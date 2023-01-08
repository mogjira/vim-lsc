function! lsc#signaturehelp#insertCharPre() abort
  let s:next_char = v:char
endfunction

if !exists('s:initialized')
  let s:current_parameter = ''
  let s:next_char = ''
  let s:initialized = v:true
endif

function! lsc#signaturehelp#textChanged() abort
  if &paste | return | endif
  if !g:lsc_enable_autocomplete | return | endif
  " This may be <BS> or similar if not due to a character typed
  if empty(s:next_char) | return | endif
  call s:typedCharacter()
  let s:next_char = ''
endfunction

function! s:typedCharacter() abort
  if s:isTrigger(s:next_char)
    call lsc#signaturehelp#getSignatureHelp()
  endif
endfunction

function! s:isTrigger(char) abort
  for l:server in lsc#server#current()
    if index(l:server.capabilities.signaturehelp.triggerCharacters, a:char) >= 0
      return v:true
    endif
  endfor
  return v:false
endfunction

function! lsc#signaturehelp#getSignatureHelp() abort
  call lsc#file#flushChanges()
  let l:params = lsc#params#documentPosition()
  " TODO handle multiple servers
  let l:server = lsc#server#forFileType(&filetype)[0]
  call l:server.request('textDocument/signatureHelp', l:params,
      \ lsc#util#gateResult('SignatureHelp', function('<SID>ShowHelp')))
endfunction

function! s:HighlightCurrentParameter() abort
  execute 'match lscCurrentParameter /\V' . s:current_parameter . '/'
endfunction

function! s:ShowHelp(signatureHelp) abort
  if empty(a:signatureHelp)
    call lsc#message#show('No signature help available')
    return
  endif
  let l:signatures = []
  if has_key(a:signatureHelp, 'signatures')
    if type(a:signatureHelp.signatures) == type([])
      let l:signatures = a:signatureHelp.signatures
    endif
  endif

  if len(l:signatures) == 0
    return
  endif

  let l:active_signature = 0
  if has_key(a:signatureHelp, 'activeSignature')
    let l:active_signature = a:signatureHelp.activeSignature
    if l:active_signature >= len(l:signatures)
      let l:active_signature = 0
    endif
  endif

  let l:signature = get(l:signatures, l:active_signature)

  if !has_key(l:signature, 'label')
    return
  endif

  if !has_key(l:signature, 'parameters')
    call lsc#util#displayAsPreview([l:signature.label], &filetype,
        \ function('<SID>HighlightCurrentParameter'))
    return
  endif

  if has_key(a:signatureHelp, 'activeParameter')
    let l:active_parameter = a:signatureHelp.activeParameter
    if l:active_parameter < len(l:signature.parameters)
        \ && has_key(l:signature.parameters[l:active_parameter], 'label')
      let s:current_parameter = l:signature.parameters[l:active_parameter].label
    endif
  endif

  call lsc#util#displayAsPreview([l:signature.label], &filetype,
      \ function('<SID>HighlightCurrentParameter'))

endfunction
