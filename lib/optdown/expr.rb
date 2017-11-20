#! /your/favourite/path/to/ruby
# -*- mode: fundamental; coding: utf-8 -*-
# -*- frozen_string_literal: true -*-
# -*- warn_indent: true -*-

# Copyright (c) 2017 Urabe, Shyouhei
#
# Permission is hereby granted, free of  charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction,  including without limitation the rights
# to use,  copy, modify,  merge, publish,  distribute, sublicense,  and/or sell
# copies  of the  Software,  and to  permit  persons to  whom  the Software  is
# furnished to do so, subject to the following conditions:
#
#         The above copyright notice and this permission notice shall be
#         included in all copies or substantial portions of the Software.
#
# THE SOFTWARE  IS PROVIDED "AS IS",  WITHOUT WARRANTY OF ANY  KIND, EXPRESS OR
# IMPLIED,  INCLUDING BUT  NOT LIMITED  TO THE  WARRANTIES OF  MERCHANTABILITY,
# FITNESS FOR A  PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO  EVENT SHALL THE
# AUTHORS  OR COPYRIGHT  HOLDERS  BE LIABLE  FOR ANY  CLAIM,  DAMAGES OR  OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require_relative 'html5entity'

# HTML5ENTITY includes  some historical  character references  that do  not end
# with ';', such as "&AMP".  They are not allowed in GFM.  We filter them out.
entre = Regexp.union Optdown::HTML5ENTITY.keys.grep(/\A\&.+\;\z/).sort.reverse

# Definitions  of  character  names  and other  nonterminals,  used  in  parser
# classes. Roughly resembles scanners.re of cmark but not the same; look at for
# instance how HTML comments are treated differently.
Optdown::EXPR = /#{sprintf(<<~'end', entre: entre)}/x

(?<SP>  \u0020 (?########################################################) ){0}
(?<TAB> \u0009 (?# This is the biggest and trickiest regular expression #) ){0}
(?<LF>  \u000A (?# that @shyouhei  had ever written so  far.  Please be #) ){0}
(?<VT>  \u000B (?# advised NOT to read through  from the top.  It's too #) ){0}
(?<FF>  \u000C (?# complicated to do so.                                #) ){0}
(?<CR>  \u000D (?########################################################) ){0}

# (Also, don't expect  your text editor to properly colorize  this file.  As of
# writing  Atom, Sublime  Text, VS  Code, RubyMine's  30 days  free trial,  and
# surprisingly Emacs all fail to understand it.  Vim does though.)

# http://spec.commonmark.org/0.28/#characters-and-lines
(?<LINE>        (?~ \g<EOL> ) \g<EOL>                                      ){0}
(?<EOL>         \g<CR> \g<LF> | \g<CR> | \g<LF> | \z                       ){0}
(?<LINE:blank>  (?: \g<SP> | \g<TAB> )* \g<EOL>                            ){0}
(?<WS>          \g<SP> | \g<TAB> | \g<LF> | \g<VT> | \g<FF> | \g<CR>       ){0}
(?<WS+>         \g<WS>+                                                    ){0}
(?<^WS>         # :FIXME: @shyouhei can't implement this using \g
                [^\u0020\u0009\u000A\u000B\u000C\u000D]                    ){0}
(?<WS:Unicode>  \g<TAB> | \g<CR> | \g<LF> | \g<FF> | \p{Zs}                ){0}
(?<WS*>         \g<WS>*                                                    ){0}
(?<WS*:EOL?>    (?<WS:^EOL> (?! \g<EOL> ) \g<WS> )*
                (?: \g<EOL> \g<WS:^EOL>* )?                                ){0}
(?<PUNCT>       \g<PUNCT:ASCII> | \p{Pc} | \p{Pd} | \p{Pe} | \p{Pf} |
                \p{Pi} | \p{Po} | \p{Ps}                                   ){0}
(?<PUNCT:ASCII> \! | \" | \# | \$ | %% | \& | \' | \( | \) | \* | \+ |
                \, | \- | \. | \/ | \: | \; | \< | \= | \> | \? | \@ |
                \[ | \\ | \] | \^ | \_ | \` | \{ | \| | \} | \~            ){0}

# http://spec.commonmark.org/0.28/#thematic-breaks
(?<indent> \g<SP>{,3} (?! \g<SP> )                                         ){0}
(?<hr:chr> \- | \_ | \*                                                    ){0}
(?<hr>     \g<hr:chr> \g<SP>* (?: \k<hr:chr> \g<SP>* ){2,} \g<EOL>         ){0}

# http://spec.commonmark.org/0.28/#atx-headings
(?<atx>       \g<atx:open> \g<atx:body> \g<atx:close>                      ){0}
(?<atx:open>  [#]{1,6} (?= \g<SP> | \g<EOL> )                              ){0}
(?<atx:close> (?: (?<= \g<SP> ) [#]* \g<SP>* )? \g<EOL>                    ){0}
(?<atx:body>  .*?                                                          ){0}

# http://spec.commonmark.org/0.28/#setext-headings
(?<sh>      \g<sh:body>+? \g<sh:ul>                                        ){0}
(?<sh:body> \g<indent> (?= \g<^WS> ) \g<LINE>                              ){0}
(?<sh:lv1>  =+                                                             ){0}
(?<sh:lv2>  -+                                                             ){0}
(?<sh:ul>   \g<indent> (?: \g<sh:lv1> | \g<sh:lv2> ) \g<WS*> \g<EOL>       ){0}

# http://spec.commonmark.org/0.28/#indented-code-block
(?<pre:indented>  \g<SP>{4}                                                ){0}

# http://spec.commonmark.org/0.28/#fenced-code-blocks
(?<pre:fenced>    \g<pre:fence> \g<SP>* \g<pre:info> \g<SP>* \g<EOL>       ){0}
(?<pre:backticks> [`]{3,}                                                  ){0}
(?<pre:tildes>    [~]{3,}                                                  ){0}
(?<pre:fence>     \g<pre:backticks> | \g<pre:tildes>                       ){0}
(?<pre:info>      [^`\u000A\u000D]*?                                       ){0}

# http://spec.commonmark.org/0.28/#html-blocks
(?<tag:block>        \g<tag:start1> | \g<tag:start2> | \g<tag:start3> |
                     \g<tag:start4> | \g<tag:start5> | \g<tag:start6> |
                     \g<tag:start7>                                        ){0}
(?<tag:cutter>       \g<tag:start1> | \g<tag:start2> | \g<tag:start3> |
                     \g<tag:start4> | \g<tag:start5> | \g<tag:start6>      ){0}
(?<tag:known>   (?i: address | article | aside | base | basefont |
                     blockquote | body | caption | center | col |
                     colgroup | dd | details | dialog | dir | div | dl |
                     dt | fieldset | figcaption | figure | footer | form |
                     frame | frameset | h1 | h2 | h3 | h4 | h5 | h6 |
                     head | header | hr | html | iframe | legend | li |
                     link | main | menu | menuitem | meta | nav |
                     noframes | ol | optgroup | option | p | param |
                     section | source | summary | table | tbody | td |
                     tfoot | th | thead | title | tr | track | ul )        ){0}
(?<tag:term>    (?= \g<WS> | > | \g<EOL> )                                 ){0}
(?<tag:start1>  (?i: <script | <pre | <style ) \g<tag:term>                ){0}
(?<tag:start2>  <!--                                                       ){0}
(?<tag:start3>  <\?                                                        ){0}
(?<tag:start4>  <! (?= [A-Z] )                                             ){0}
(?<tag:start5>  <!\[CDATA\[                                                ){0}
(?<tag:start6>  (?: < | </ )   \g<tag:known> (?: \g<tag:term> | /> )       ){0}
(?<tag:start7>  \g<tag:complete>                                           ){0}
(?<tag:end1>    (?i: </script> | </pre> | </style> )                       ){0}
(?<tag:end2>    -->                                                        ){0}
(?<tag:end3>    \?>                                                        ){0}
(?<tag:end4>    >                                                          ){0}
(?<tag:end5>    \]\]>                                                      ){0}

(?<tag:complete>     (?= \g<tag:completeness> )
                     (?: \g<tag:open> | \g<tag:close> )                    ){0}
(?<tag:completeness> < (?:   [^\u000A\u000D\u003E]*+   |
                           " [^\u000A\u000D\u0022]*+ " |
                           ' [^\u000A\u000D\u0027]*+ ' )+
                     > \g<LINE:blank>                                      ){0}

# http://spec.commonmark.org/0.28/#link-reference-definitions
(?<link:def> \g<link:label> [:] \g<WS*:EOL?>
             \g<link:dest> \g<link:pair:title>? \g<WS*> \g<EOL>            ){0}

# http://spec.commonmark.org/0.28/#block-quotes
(?<blockquote> [>] \g<SP>?                                                 ){0}

# http://spec.commonmark.org/0.28/#list-items
# https://github.github.com/gfm/#task-list-items-extension-
(?<li>        \g<li:marker> \g<li:train>                                   ){0}
(?<li:bullet> [-+*]                                                        ){0}
(?<li:num>    \d{1,9}                                                      ){0}
(?<li:mark>   [\)\.]                                                       ){0}
(?<li:marker> \g<li:bullet> | \g<li:num> \g<li:mark>                       ){0}
(?<li:normal> \g<SP>{1,4} (?! \g<EOL> )                                    ){0}
(?<li:pre>    \g<SP> (?= \g<SP>{4} )                                       ){0}
(?<li:eol>    (?= \g<WS>* \g<EOL> )                                        ){0}
(?<li:task>   \g<SP>{1,4} \[ (?: \g<SP> | x ) \] (?= \g<SP> )              ){0}
(?<li:train>  \g<li:pre> | \g<li:eol> | \g<li:task> | \g<li:normal>        ){0}
(?<li:cutter> \g<li:bullet>      \g<SP>+ (?! \g<WS> ) . |
              0{,8}1 \g<li:mark> \g<SP>+ (?! \g<WS> ) .                    ){0}

# http://spec.commonmark.org/0.28/#lazy-continuation-line
#
# Note,  when the  spec says  the "setext  heading underline  cannot be  a lazy
# continuation  line", that  means the  underline shall  be treated  as literal
# strings inside of a paragraph, not a separated blocklevel.
#
# HOWEVER, the level 2 setext underline  "----" is also a valid thematic break.
# Since a  thematic break  can interrupt  a paragraph as  shown below,  level 2
# setext underline can never be a part of a lazy continuation line.
#
# So in short  the level 1 setext  underline is the only  setext underline that
# can form a lazy continuation paragraph.
(?<p:cutter> \g<indent>
             (?= \g<LINE:blank> | \g<hr> | \g<blockquote> | \g<li:cutter> |
                 \g<tag:cutter> | \g<pre:fenced> | \g<atx> | \z )          ){0}

(?<blocklevel:fastpath> \g<indent>
                        (?: \g<hr> | \g<link:def> | \g<blockquote> |
                            \g<li> | \g<tag:block> | \g<pre:fenced> |
                            \g<atx> | \g<LINE:blank>+ )                    ){0}

# https://github.github.com/gfm/#tables-extension-
(?<table:delim>    \g<WS:GH>* (?: \G | (?<! \\ ) ) \| \g<WS:GH>*           ){0}
(?<table:td>       (?~ \g<table:delim> | \g<EOL> )                         ){0}
(?<table:-->       [:]? [-]+ [:]?                                          ){0}
# `- | -` is a valid deimiter row, but it seems they parse such line as a list.
(?<table:open>     \g<indent> (?! \g<li> ) \g<table:delim>?                ){0}
(?<table:close>    \g<table:delim>? \g<EOL>                                ){0}
(?<table:tr>       \g<table:td> (?: \g<table:delim> \g<table:td> )*        ){0}
(?<table:dr>       \g<table:--> (?: \g<table:delim> \g<table:--> )*        ){0}
(?<table:th>       \g<table:tr>                                            ){0}
(?<table>          (?= (?# optimize ) .+ \g<EOL> [-:|\u0020]+ \g<EOL> )
                   \g<table:open> \g<table:th> \g<table:close>
                   \g<table:open> \g<table:dr> \g<table:close>
               (?: \g<table:open> \g<table:tr> \g<table:close> )*          ){0}
(?<WS:GH>          \g<SP> | \g<TAB> | \g<VT> | \g<FF>                      ){0}

# http://spec.commonmark.org/0.28/#backslash-escapes
#
#           +-+ This is wrong.
#           | |
# ... x y \ \ z w ...
#         | |
#         +-+ This must be matched.
(?<escape>  (?> \\ \g<PUNCT:ASCII> )                                       ){0}
(?<escape+> (?> (?<! \\ ) \g<escape>+ )                                    ){0}

# http://spec.commonmark.org/0.28/#entity-and-numeric-character-references
(?<entity>       \& \# [Xx] (?<entity:hex> \h{1,8} ) \; |
                 \& \#      (?<entity:dec> \d{1,8} ) \; |
                 \g<entity:named>                                          ){0}
(?<entity:named> (?= (?# optimize ) \& [A-Za-z]+ \d* \; )
                 %<entre>s                                                 ){0}

# http://spec.commonmark.org/0.28/#code-spans
(?<code>       \g<code:start> \g<code:body> \g<code:term>                  ){0}
(?<code:start> (?: \G | (?<! \` ) ) \`++                                   ){0}
(?<code:term>  (?<! \` ) \k<code:start> (?! \` )                           ){0}
(?<code:body>  (?m:.+?)                                                    ){0}

# http://spec.commonmark.org/0.28/#emphasis-and-strong-emphasis
# https://github.github.com/gfm/#strikethrough-extension-
(?<flanker:and>   (?= \g<flanker:left> ) \g<flanker:right>                 ){0}
(?<flanker:or>        \g<flanker:left> | \g<flanker:right>                 ){0}
(?<flanker:run>       \g<flanker:run:*> | \g<flanker:run:_> |
                      \g<flanker:run:~>                                    ){0}
# beware of the tactically placed \g and \k below...
(?<flanker:left>      (?= \g<flanker:left:a> ) \g<flanker:left:b>          ){0}
(?<flanker:left:a>    \g<flanker:run> (?! \g<WS:Unicode> | \z )            ){0}
(?<flanker:left:b>    \g<flanker:left:b:1> | \g<flanker:left:b:2>          ){0}
(?<flanker:left:b:1>  \k<flanker:run> (?! \g<PUNCT> )                      ){0}
(?<flanker:left:b:2>  (?<= \A | \g<WS:Unicode> | \g<PUNCT> )
                      \k<flanker:run>                                      ){0}
(?<flanker:right>     (?= \g<flanker:right:a> ) \g<flanker:right:b>        ){0}
(?<flanker:right:a>   (?<! \A | \g<WS:Unicode> ) \g<flanker:run>           ){0}
(?<flanker:right:b>   \g<flanker:right:b:1> | \g<flanker:right:b:2>        ){0}
(?<flanker:right:b:1> (?<! \g<PUNCT> ) \k<flanker:run>                     ){0}
(?<flanker:right:b:2> \k<flanker:run> (?= \g<WS:Unicode> | \g<PUNCT> | \z )){0}
(?<flanker:run:*>     (?: \G | (?<! \* ) ) \*++                            ){0}
(?<flanker:run:_>     (?: \G | (?<! \_ ) ) \_++                            ){0}
(?<flanker:run:~>     (?: \G | (?<! \~ ) ) \~++                            ){0}

# http://spec.commonmark.org/0.28/#links
# http://spec.commonmark.org/0.28/#images
(?<link>            (?: \g<img:left> | \g<a:left> | \g<a:right> )          ){0}
(?<img:left>        \! \[                                                  ){0}
(?<a:left>          \[                                                     ){0}
(?<a:right>         \] \g<a:href>                                          ){0}
(?<a:href>          \g<a:inline>    | (?= \g<link:label> ) |
                    \g<a:collapsed> | \g<a:shortcut>                       ){0}
(?<a:inline>        \( \g<WS*> \g<link:pair> \g<WS*> \)                    ){0}
(?<a:collapsed>     \[ \]                                                  ){0}
(?<a:shortcut>      (?! \[ )                                               ){0}
(?<link:dest>       < \g<link:dest:a> > | \g<link:dest:b>                  ){0}
(?<link:dest:a>     (?: (?> \\ \< ) | (?> \\ \> ) |
                        [^<\u0020\u000A\u000D>] )*                         ){0}
(?<link:dest:b:a>   (?: (?> \\ \( ) | (?> \\ \) ) | [^\(\u0000-\u0020\)] )*){0}
(?<link:dest:b:b>   \( \g<link:dest:b> \)                                  ){0}
(?<link:dest:b>     (?! <) # https://github.com/commonmark/cmark/issues/229
                    (?= \g<^WS> ) # nonempty constraint
                    (?: \g<link:dest:b:a> | \g<link:dest:b:b> )+           ){0}
(?<link:title>      \g<link:title:2> | \g<link:title:1> | \g<link:title:0> ){0}
(?<link:title:2>    \" \g<link:title:2j> \"                                ){0}
(?<link:title:1>    \' \g<link:title:1j> \'                                ){0}
(?<link:title:0>    \( \g<link:title:0j> \)                                ){0}
(?<link:title:2j>    \g<link:title:2i>*                                    ){0}
(?<link:title:1j>    \g<link:title:1i>*                                    ){0}
(?<link:title:0j>    \g<link:title:0i>*                                    ){0}
(?<link:title:2i>   (?> \\ \" ) | \g<EOL> (?! \g<EOL> ) | [^\"\u000A\u000D]){0}
(?<link:title:1i>   (?> \\ \' ) | \g<EOL> (?! \g<EOL> ) | [^\'\u000A\u000D]){0}
(?<link:title:0i>   (?> \\ \) ) | \g<EOL> (?! \g<EOL> ) | [^\)\u000A\u000D]){0}
(?<link:label>      \[ (?= \g<link:label:^WS> ) \g<link:label:999> \]      ){0}
(?<link:label:^WS>  \g<WS*> (?= \g<^WS> ) [^\]]                            ){0}
(?<link:label:999>  (?: (?> \\ \] ) | (?> \\ \[ ) | [^\[\]] ){1,999}       ){0}
(?<link:pair>       \g<link:dest>? \g<link:pair:title>?                    ){0}
(?<link:pair:title> \g<WS*:EOL?> (?(<link:dest>) (?<= \g<WS>) )
                    \g<link:title>                                         ){0}

# http://spec.commonmark.org/0.28/#autolinks
(?<auto>            < (?: \g<auto:URI> | \g<auto:mail> ) >                 ){0}
(?<auto:URI>        \g<auto:URI:scheme> \: ([^<\u0000-\u0020>])*           ){0}
(?<auto:URI:scheme> [a-zA-Z] [a-zA-Z0-9+.-]{1,31}                          ){0}
(?<auto:mail>       \g<HTML5:email>                                        ){0}

# https://html.spec.whatwg.org/multipage/input.html
(?<HTML5:email>   (?: \g<HTML5:atext> | \. )+ [@]
                  \g<HTML5:label> (?: \. \g<HTML5:label> )*                ){0}
(?<HTML5:label>   \g<HTML5:let-dig>
                  (?: \g<HTML5:ldh-str>{,61} \g<HTML5:let-dig> )?          ){0}
(?<HTML5:atext>   [a-zA-Z0-9!#$%%&'*+/=?^_`{|}~-]                          ){0}
(?<HTML5:let-dig> [a-zA-Z0-9]                                              ){0}
(?<HTML5:ldh-str> [a-zA-Z0-9-]                                             ){0}

# https://github.github.com/gfm/#autolinks-extension-
(?<auto:GH>        \g<auto:GH:cond> (?:
                   \g<auto:GH:www> | \g<auto:GH:url> | \g<auto:GH:email> ) ){0}
(?<auto:GH:cond>   \g<BOL> | (?<= \g<WS> ) | (?<= [*_~(] )                 ){0}
(?<BOL>            \A | (?<= \g<CR> \g<LF> | \g<CR> | \g<LF> )             ){0}
(?<auto:GH:www>    www\. \g<auto:GH:domain> \g<auto:GH:path>               ){0}
(?<auto:GH:domain> (?: [a-zA-Z0-9_-]+ \. )*
                   \g<auto:GH:CC> \. \g<auto:GH:TLD>                       ){0}
(?<auto:GH:CC>     [a-zA-Z0-9-]+                                           ){0}
(?<auto:GH:TLD>    [a-zA-Z0-9-]+ (?<! - | _ )                              ){0}
(?<auto:GH:path>   [^\u0020\u0009\u000A\u000B\u000C\u000D\u003C]*?
                   # see also inline.rb for paren validations
                   (?= (?: \g<auto:GH:punct> | \g<entity:named> )?
                       (?: \g<WS> | \g<EOL> | < ) )                        ){0}
(?<auto:GH:punct>  [\?\!\.\,\:\*\_\~]                                      ){0}
(?<auto:GH:url>    \g<auto:GH:scheme> \g<auto:GH:domain> \g<auto:GH:path>  ){0}
(?<auto:GH:scheme> http:// | https:// | ftp://                             ){0}
(?<auto:GH:email>  \g<auto:GH:user> [@] \g<auto:GH:domain> (?! - | _ )     ){0}
(?<auto:GH:user>   [a-zA-Z0-9\.\_\+\-]+                                    ){0}

# http://spec.commonmark.org/0.28/#raw-html
(?<tag:name>       [a-zA-Z] [a-zA-Z0-9-]*                                  ){0}
(?<tag:attr>       \g<WS+> \g<tag:attr:name> \g<tag:attr:spec>?            ){0}
(?<tag:attr:name>  [a-zA-Z_:] [a-zA-Z0-9_.:-]*                             ){0}
(?<tag:attr:spec>  \g<WS*> [=] \g<WS*> \g<tag:attr:val>                    ){0}
(?<tag:attr:val>   \g<tag:attr:val:0> | \g<tag:attr:val:1> |
                   \g<tag:attr:val:2>                                      ){0}
(?<tag:attr:val:0> [^ \"\'\=\<\>\`]+                                       ){0}
(?<tag:attr:val:1> ' [^\']* '                                              ){0}
(?<tag:attr:val:2> " [^\"]* "                                              ){0}
(?<tag:open>       < \g<tag:name> \g<tag:attr>* \g<WS*> /? >               ){0}
(?<tag:close>      </ \g<tag:name> \g<WS*> >                               ){0}
(?<tag:comment>    <!-- (?! -> | > ) (?~ -- ) (?<! - ) -->                 ){0}
(?<tag:xmlproc>    <\? (?~ \?> ) \?>                                       ){0}
(?<tag:doctype>    <\! [A-Z]+ \g<WS+> (?~ > ) >                            ){0}
(?<tag:CDATA>      <\! \[CDATA\[  (?~ \]\]> ) \]\]>                        ){0}
(?<tag>            \g<tag:open>    | \g<tag:close>   | \g<tag:comment> |
                   \g<tag:xmlproc> | \g<tag:doctype> | \g<tag:CDATA>       ){0}

# http://spec.commonmark.org/0.28/#hard-line-breaks
(?<br>      (?: \g<br:hard> | \g<br:soft> ) \g<EOL> \g<SP>* (?! \z )       ){0}
(?<br:hard> \g<SP>{2,} | \u005C                                            ){0}
(?<br:soft> \g<SP>?                                                        ){0}

(?<inline:cutter> \g<escape+> | \g<entity> | \g<code> | \g<auto> |
                  \g<auto:GH> | \g<tag> | \g<br> | \g<link> |
                  \g<flanker:and> | \g<flanker:or> | \g<table:delim>       ){0}
end
