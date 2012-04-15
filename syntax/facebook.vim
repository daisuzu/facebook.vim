if exists('b:current_syntax')
    finish
endif

syntax match facebook_others "^\S*:.*"
syntax match facebook_link "^link:"
syntax match facebook_link_url "http[s]*://.*"
syntax region facebook_name matchgroup=facebook_time start="^\[.*\] " matchgroup=facebook_action_url end="http[s]*://.*"
syntax region facebook_paging matchgroup=facebook_prev start="previous:" matchgroup=facebook_prev_url end="http[s]*://.*"
syntax match facebook_comments "^comments:\d*"
syntax match facebook_likes "^like:\d*"

hi def link facebook_others Special
hi def link facebook_link Ignore
hi def link facebook_link_url Underlined
hi def link facebook_time Title
hi def link facebook_name Constant
hi def link facebook_action_url Ignore
hi def link facebook_prev Type
hi def link facebook_prev_url Ignore
hi def link facebook_comments Identifier
hi def link facebook_likes Identifier

let b:current_syntax = 'facebook'
