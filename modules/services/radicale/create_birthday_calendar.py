#!/usr/bin/env python
import fileinput
import glob
import json
import os
import random
import sys
import uuid

from collections import defaultdict
from datetime import datetime, timedelta
from typing import Iterator, Any

import dateutil.rrule as rrule
import vobject

BIRTHDAY_REMINDER_AT_HOUR = 8


def parse_date(date_str):
    for date_fmt in ('%Y-%m-%d', '%Y%m%d', '--%m%d'):
        try:
            return datetime.strptime(date_str, date_fmt)
        except ValueError:
            pass
    raise ValueError(f'could not parse date {date_str}')


def get_changed_files() -> dict[str, list[str]]:
    paths = sys.argv[1:]
    if paths:
        pwd = os.getcwd()
        paths = [path.split(pwd + "/")[-1] for path in paths]
    else:
        paths = glob.glob("**/*", recursive=True)
    user_modifications = defaultdict(list)
    for path in paths:
        if not os.path.isfile(path) or not path.count('/') >= 3:
            continue
        root, user, collection, file = path.split('/', maxsplit=3)
        user_modifications[f'{root}/{user}'].append(f'{collection}/{file}')
    return user_modifications


def get_user_collections(user: str) -> dict[str, str]:
    user_collections = {}
    dirpath, dirnames, filenames = next(os.walk(user), ([], [], []))
    for collection in dirnames:
        try:
            with open(f'{user}/{collection}/.Radicale.props', 'r') as fp:
                tag = json.load(fp)['tag']
        except (FileNotFoundError, json.JSONDecodeError, KeyError):
            continue
        else:
            user_collections[collection] = tag
    return user_collections


def get_entries(collection: str) -> Iterator[tuple[str, Any]]:
    dirpath, dirnames, filenames = next(os.walk(collection), ([], [], []))
    for filename in filenames:
        if filename.startswith('.Radicale'):
            continue
        with open(f'{dirpath}/{filename}', 'r') as fp:
            for entry in vobject.readComponents(fp.read()):
                yield f'{collection}/{filename}', entry


def get_birthday_calendar(user: str) -> Iterator[tuple[str, Any]]:
    collection = f'{user}/birthdays'
    if not os.path.exists(collection):
        os.makedirs(collection, exist_ok=True)
    fn = f'{collection}/.Radicale.props'
    if not os.path.exists(fn):
        with open(fn, 'w') as fp:
            # (Optional) Get calendar color from environment
            color = os.getenv("BIRTHDAY_CALENDAR_COLOR")
            if color:
                # If color was set, strip '#' for consistency
                color = color.strip('#')
            else:
                # Or alternatively choose something at random
                color = ''.join(random.choices('0123456abcdef', k=6))

            data = {
                'C:supported-calendar-component-set': 'VEVENT',
                'D:displayname': 'Birthdays',
                'C:calendar-description': '[AUTO GENERATED] Birthdays from all addressbooks',
                'ICAL:calendar-color': f'#{color}',
                'tag': 'VCALENDAR'}
            json.dump(data, fp, indent=None)
    yield from get_entries(collection)


def get_birth_year(date_str: str):
    if date_str.startswith('--'):
        return None
    try:
        return str(parse_date(date_str).year)
    except ValueError:
        return None


def create_birthday(user: str, contact, remind_hour: int = BIRTHDAY_REMINDER_AT_HOUR):
    calendar = vobject.iCalendar()

    # Basic event properties
    event = calendar.add('vevent')
    birth_year = get_birth_year(contact.bday.value)
    if birth_year:
        event.add('summary').value = f"🎂 {contact.fn.value} ({birth_year})"
    else:
        event.add('summary').value = f"🎂 {contact.fn.value}"
    event.add('dtstart').value = parse_date(contact.bday.value).date()
    event.add('dtend').value = event.dtstart.value + timedelta(days=1)
    event.add('uid').value = contact.uid.value

    alarm = event.add('valarm')
    alarm.add('action').value = 'DISPLAY'
    alarm.add('description').value = 'Reminder'
    alarm.add('trigger').value = timedelta(hours=remind_hour)
    alarm.add('uid').value = str(uuid.uuid4())

    # Repeat yearly
    newrule = rrule.rruleset()
    newrule.rrule(rrule.rrule(rrule.YEARLY, dtstart=event.dtstart.value))
    event.rruleset = newrule

    # Write to disk
    collection = f'{user}/birthdays'
    with open(f'{collection}/{contact.uid.value}.ics', 'w') as fp:
        fp.write(calendar.serialize())


def main():
    user_to_changes = get_changed_files()
    user_to_collections = {user: get_user_collections(user) for user in user_to_changes}

    for user, changed_files in user_to_changes.items():
        contacts = {contact.uid.value: contact
                    for collection, tag in user_to_collections[user].items() if tag == 'VADDRESSBOOK'
                    for _, contact in get_entries(f'{user}/{collection}') if hasattr(contact, 'bday')}
        birthday_entries = {user_bday.vevent.uid.value: (fn, user_bday) for fn, user_bday in
                            get_birthday_calendar(user)}

        # Check existing birthday entries
        for bday_uid, (bday_file, bday_event) in birthday_entries.items():
            # Delete old ones
            if bday_uid not in contacts:
                os.unlink(bday_file)
            # Keep unchanged
            elif not any(bday_uid in changed_file for changed_file in changed_files):
                del contacts[bday_uid]

        # Write new and modified contacts
        for contact in contacts.values():
            create_birthday(user, contact)


if __name__ == '__main__':
    main()
