" =============================================================================
" URL: https://github.com/genmzy/moonlight
" Filename: autoload/moonlight.vim
" Author: genmzy
" Email: genmzy@gmail.com
" License: MIT License
" =============================================================================

" g:moonlight#tmux: is in tmux < 2.9 or not {{{
let g:moonlight#tmux = executable('tmux') && $TMUX !=# '' ?
                  \ (str2float(system("tmux -V | grep -oE '[0-9]+\.[0-9]*'")) < 2.9 ?
                    \ 1 :
                    \ 0) :
                  \ 0 "}}}
function! moonlight#get_configuration() "{{{
  return {
        \ 'background': get(g:, 'moonlight_background', 'medium'),
        \ 'transparent_background': get(g:, 'moonlight_transparent_background', 0),
        \ 'disable_italic_comment': get(g:, 'moonlight_disable_italic_comment', 0),
        \ 'enable_italic': get(g:, 'moonlight_enable_italic', 0),
        \ 'cursor': get(g:, 'moonlight_cursor', 'auto'),
        \ 'menu_selection_background': get(g:, 'moonlight_menu_selection_background', 'white'),
        \ 'sign_column_background': get(g:, 'moonlight_sign_column_background', 'default'),
        \ 'current_word': get(g:, 'moonlight_current_word', get(g:, 'moonlight_transparent_background', 0) == 0 ? 'grey background' : 'bold'),
        \ 'lightline_disable_bold': get(g:, 'moonlight_lightline_disable_bold', 0),
        \ 'diagnostic_text_highlight': get(g:, 'moonlight_diagnostic_text_highlight', 0),
        \ 'diagnostic_line_highlight': get(g:, 'moonlight_diagnostic_line_highlight', 0),
        \ 'diagnostic_virtual_text': get(g:, 'moonlight_diagnostic_virtual_text', 'grey'),
        \ 'better_performance': get(g:, 'moonlight_better_performance', 0),
        \ }
endfunction "}}}

function! moonlight#get_palette(background) "{{{
  let palette1 = {
        \ 'bg0':        ['#212539',   '234',  'Black'],
        \ 'bg1':        ['#292e46',   '235',  'DarkGrey'],
        \ 'bg2':        ['#2a2e48',   '236',  'DarkGrey'],
        \ 'bg3':        ['#383e5c',   '238',  'DarkGrey'],
        \ 'bg4':        ['#4E5579',   '239',  'DarkGrey'],
        \ 'bg_visual':  ['#5b6395',   '52',   'DarkRed'],
        \ 'bg_red':     ['#4e3e43',   '52',   'DarkRed'],
        \ 'bg_green':   ['#404d44',   '22',   'DarkGreen'],
        \ 'bg_blue':    ['#394f5a',   '17',   'DarkBlue'],
        \ 'bg_yellow':  ['#4a4940',   '136',  'DarkBlue'],
        \ }
  let palette2 = {
        \ 'fg':         ['#e4f3fa',   '223',  'White'],
        \ 'red':        ['#FF5370',   '167',  'Red'],
        \ 'orange':     ['#ff9668',   '167',  'Red'],
        \ 'yellow':     ['#ffdf9b',   '214',  'Yellow'],
        \ 'green':      ['#c7f59b',   '208',  'Green'],
        \ 'aqua':       ['#7af8ca',   '108',  'Cyan'],
        \ 'blue':       ['#7fdaff',   '109',  'Blue'],
        \ 'purple':     ['#baacff',   '175',  'Magenta'],
        \ 'grey0':      ['#969bb8',   '243',  'DarkGrey'],
        \ 'grey1':      ['#7e8eda',   '245',  'Grey'],
        \ 'grey2':      ['#7c85b3',   '247',  'LightGrey'],
        \ 'statusline1':['#baacff',   '142',  'Green'],
        \ 'statusline2':['#969bb8',   '223',  'White'],
        \ 'statusline3':['#ff9668',   '167',  'Red'],
        \ 'none':       ['NONE',      'NONE', 'NONE']
        \ } "}}}
  return extend(palette1, palette2)
endfunction "}}}
function! moonlight#highlight(group, fg, bg, ...) "{{{
  execute 'highlight' a:group
        \ 'guifg=' . a:fg[0]
        \ 'guibg=' . a:bg[0]
        \ 'ctermfg=' . a:fg[1]
        \ 'ctermbg=' . a:bg[1]
        \ 'gui=' . (a:0 >= 1 ?
          \ (a:1 ==# 'undercurl' ?
            \ (g:moonlight#tmux ?
              \ 'underline' :
              \ 'undercurl') :
            \ a:1) :
          \ 'NONE')
        \ 'cterm=' . (a:0 >= 1 ?
          \ (a:1 ==# 'undercurl' ?
            \ 'underline' :
            \ a:1) :
          \ 'NONE')
        \ 'guisp=' . (a:0 >= 2 ?
          \ a:2[0] :
          \ 'NONE')
endfunction "}}}
function! moonlight#ft_gen(path, last_modified, msg) "{{{
  " Generate the `after/ftplugin` directory.
  let full_content = join(readfile(a:path), "\n") " Get the content of `colors/moonlight.vim`
  let ft_content = []
  let rootpath = moonlight#ft_rootpath(a:path) " Get the path to place the `after/ftplugin` directory.
  call substitute(full_content, '" ft_begin.\{-}ft_end', '\=add(ft_content, submatch(0))', 'g') " Search for 'ft_begin.\{-}ft_end' (non-greedy) and put all the search results into a list.
  for content in ft_content
    let ft_list = []
    call substitute(matchstr(matchstr(content, 'ft_begin:.\{-}{{{'), ':.\{-}{{{'), '\(\w\|-\)\+', '\=add(ft_list, submatch(0))', 'g') " Get the file types. }}}}}}
    for ft in ft_list
      call moonlight#ft_write(rootpath, ft, content) " Write the content.
    endfor
  endfor
  call moonlight#ft_write(rootpath, 'text', "let g:moonlight_last_modified = '" . a:last_modified . "'") " Write the last modified time to `after/ftplugin/text/moonlight.vim`
  if a:msg ==# 'update'
    echohl WarningMsg | echom '[moonlight] Updated ' . rootpath . '/after/ftplugin' | echohl None
  else
    echohl WarningMsg | echom '[moonlight] Generated ' . rootpath . '/after/ftplugin' | echohl None
  endif
endfunction "}}}
function! moonlight#ft_write(rootpath, ft, content) "{{{
  " Write the content.
  let ft_path = a:rootpath . '/after/ftplugin/' . a:ft . '/moonlight.vim' " The path of a ftplugin file.
  " create a new file if it doesn't exist
  if !filereadable(ft_path)
    call mkdir(a:rootpath . '/after/ftplugin/' . a:ft, 'p')
    call writefile([
          \ "if !exists('g:colors_name') || g:colors_name !=# 'moonlight'",
          \ '    finish',
          \ 'endif'
          \ ], ft_path, 'a') " Abort if the current color scheme is not moonlight.
    call writefile([
          \ "if index(g:moonlight_loaded_file_types, '" . a:ft . "') ==# -1",
          \ "    call add(g:moonlight_loaded_file_types, '" . a:ft . "')",
          \ 'else',
          \ '    finish',
          \ 'endif'
          \ ], ft_path, 'a') " Abort if this file type has already been loaded.
  endif
  " If there is something like `call moonlight#highlight()`, then add
  " code to initialize the palette and configuration.
  if matchstr(a:content, 'moonlight#highlight') !=# ''
    call writefile([
          \ 'let s:configuration = moonlight#get_configuration()',
          \ 'let s:palette = moonlight#get_palette(s:configuration.background)'
          \ ], ft_path, 'a')
  endif
  " Append the content.
  call writefile(split(a:content, "\n"), ft_path, 'a')
endfunction "}}}
function! moonlight#ft_rootpath(path) "{{{
  " Get the directory where `after/ftplugin` is generated.
  if (matchstr(a:path, '^/usr/share') ==# '') || has('win32') " Return the plugin directory. The `after/ftplugin` directory should never be generated in `/usr/share`, even if you are a root user.
    return fnamemodify(a:path, ':p:h:h')
  else " Use vim home directory.
    if has('nvim')
      return stdpath('config')
    else
      if has('win32') || has ('win64')
        return $VIM . '/vimfiles'
      else
        return $HOME . '/.vim'
      endif
    endif
  endif
endfunction "}}}
function! moonlight#ft_newest(path, last_modified) "{{{
  " Determine whether the current ftplugin files are up to date by comparing the last modified time in `colors/moonlight.vim` and `after/ftplugin/text/moonlight.vim`.
  let rootpath = moonlight#ft_rootpath(a:path)
  execute 'source ' . rootpath . '/after/ftplugin/text/moonlight.vim'
  return a:last_modified ==# g:moonlight_last_modified ? 1 : 0
endfunction "}}}
function! moonlight#ft_clean(path, msg) "{{{
  " Clean the `after/ftplugin` directory.
  let rootpath = moonlight#ft_rootpath(a:path)
  " Remove `after/ftplugin/**/moonlight.vim`.
  let file_list = split(globpath(rootpath, 'after/ftplugin/**/moonlight.vim'), "\n")
  for file in file_list
    call delete(file)
  endfor
  " Remove empty directories.
  let dir_list = split(globpath(rootpath, 'after/ftplugin/*'), "\n")
  for dir in dir_list
    if globpath(dir, '*') ==# ''
      call delete(dir, 'd')
    endif
  endfor
  if globpath(rootpath . '/after/ftplugin', '*') ==# ''
    call delete(rootpath . '/after/ftplugin', 'd')
  endif
  if globpath(rootpath . '/after', '*') ==# ''
    call delete(rootpath . '/after', 'd')
  endif
  if a:msg
    echohl WarningMsg | echom '[moonlight] Cleaned ' . rootpath . '/after/ftplugin' | echohl None
  endif
endfunction "}}}
function! moonlight#ft_exists(path) "{{{
  return filereadable(moonlight#ft_rootpath(a:path) . '/after/ftplugin/text/moonlight.vim')
endfunction "}}}

" vim: set sw=2 ts=2 sts=2 et tw=80 ft=vim fdm=marker fmr={{{,}}}:
