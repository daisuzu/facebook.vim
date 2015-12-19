#!/usr/bin/env python

import fbconsole as fb


def main(access_token_file='.fb_access_token'):
    fb.APP_ID = "265270133561898"
    fb.ACCESS_TOKEN_FILE = access_token_file
    fb.AUTH_SCOPE = [
        'public_profile',
        'user_friends',
        'email',
        'user_about_me',
        'user_actions.books',
        'user_actions.fitness',
        'user_actions.music',
        'user_actions.news',
        'user_actions.video',
        'user_birthday',
        'user_education_history',
        'user_events',
        'user_games_activity',
        'user_hometown',
        'user_likes',
        'user_location',
        'user_managed_groups',
        'user_photos',
        'user_posts',
        'user_relationships',
        'user_relationship_details',
        'user_religion_politics',
        'user_tagged_places',
        'user_videos',
        'user_website',
        'user_work_history',
        'read_custom_friendlists',
        'read_insights',
        'read_page_mailboxes',
        'manage_pages',
        'publish_pages',
        'publish_actions',
        'rsvp_event',
        'ads_read',
        'ads_management',
    ]
    fb.authenticate()

if __name__ == '__main__':
    import sys

    try:
        main(sys.argv[1])
    except IndexError:
        main()
