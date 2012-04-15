#!/usr/bin/env python

import fbconsole as fb


def main(access_token_file='.fb_access_token'):
    fb.APP_ID = "265270133561898"
    fb.ACCESS_TOKEN_FILE = access_token_file
    fb.AUTH_SCOPE = [
            # User and Friends Permissions
            'user_about_me',
            'friends_about_me',
            'user_activities',
            'friends_activities',
            'user_birthday',
            'friends_birthday',
            'user_checkins',
            'friends_checkins',
            'user_education_history',
            'friends_education_history',
            'user_events',
            'friends_events',
            'user_groups',
            'friends_groups',
            'user_hometown',
            'friends_hometown',
            'user_interests',
            'friends_interests',
            'user_likes',
            'friends_likes',
            'user_location',
            'friends_location',
            'user_notes',
            'friends_notes',
            'user_photos',
            'friends_photos',
            'user_questions',
            'friends_questions',
            'user_relationships',
            'friends_relationships',
            'user_relationship_details',
            'friends_relationship_details',
            'user_religion_politics',
            'friends_religion_politics',
            'user_status',
            'friends_status',
            'user_videos',
            'friends_videos',
            'user_website',
            'friends_website',
            'user_work_history',
            'friends_work_history',
            'email',
            # Extended Permissions
            'read_friendlists',
            'read_insights',
            'read_mailbox',
            'read_requests',
            'read_stream',
            'xmpp_login',
            'ads_management',
            'create_event',
            'manage_friendlists',
            'manage_notifications',
            'user_online_presence',
            'friends_online_presence',
            'publish_checkins',
            'publish_stream',
            'rsvp_event',
            # Open Graph Permissions
            'publish_actions',
            'user_actions.music',
            'friends_actions.music',
            'user_actions.news',
            'friends_actions.news',
            'user_actions.video',
            'friends_actions.video',
    ]
    fb.authenticate()

if __name__ == '__main__':
    import sys

    try:
        main(sys.argv[1])
    except IndexError:
        main()
