let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_facebook_vim')
  finish
endif

if !exists('g:facebook_access_token_file')
  let g:facebook_access_token_file = expand('~/.fb_access_token')
endif

if !exists('g:facebook_timezone')
  let g:facebook_timezone = '+0900'
endif

command! FacebookHome         : call facebook#home()
command! FacebookFeed         : call facebook#feed()
command! FacebookWallPost     : call facebook#wallpost()
command! FacebookAuthenticate : call facebook#authenticate()

let g:loaded_facebook_vim = 1

let &cpo = s:save_cpo
unlet s:save_cpo
