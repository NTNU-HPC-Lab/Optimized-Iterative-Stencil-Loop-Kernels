#! /usr/bin/env python
# LR(1) parser, autogenerated on 2011-05-26 21:07:45
# generator: wisent 0.6.1, http://seehuhn.de/pages/wisent
# source: vartree.wi

# All parts of this file which are not taken verbatim from the input grammar
# are covered by the following notice:
#
# Copyright (C) 2008, 2009  Jochen Voss <voss@seehuhn.de>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#   1. Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#
#   2. Redistributions in binary form must reproduce the above
#      copyright notice, this list of conditions and the following
#      disclaimer in the documentation and/or other materials provided
#      with the distribution.
#
#   3. The name of the author may not be used to endorse or promote
#      products derived from this software without specific prior
#      written permission.
#
# This software is provided by the author "as is" and any express or
# implied warranties, including, but not limited to, the implied
# warranties of merchantability and fitness for a particular purpose
# are disclaimed.  In no event shall the author be liable for any
# direct, indirect, incidental, special, exemplary, or consequential
# damages (including, but not limited to, procurement of substitute
# goods or services; loss of use, data, or profits; or business
# interruption) however caused and on any theory of liability, whether
# in contract, strict liability, or tort (including negligence or
# otherwise) arising in any way out of the use of this software, even
# if advised of the possibility of such damage.

from itertools import chain

class Unique(object):

    """Unique objects for use as markers.

    These objects are internally used to represent the start symbol
    and the end-of-input marker of the grammar.
    """

    def __init__(self, label):
        """Create a new unique object.

        `label` is a string which is used as a textual representation
        of the object.
        """
        self.label = label

    def __repr__(self):
        """Return the `label` given at object construction."""
        return self.label

class Parser(object):

    """LR(1) parser class.

    terminal symbols:
      'COMMA', 'LBRACE', 'RBRACE', 'VAR'

    nonterminal symbols:
      'VARTREE', 'VARTREE_BR'

    production rules:
      'VARTREE' -> 'LBRACE' '_LIST' 'RBRACE'
      'VARTREE' -> '_FLATLIST'
      'VARTREE_BR' -> 'LBRACE' '_LIST' 'RBRACE'
      '_LIST' -> '_ELEMENT'
      '_LIST' -> '_ELEMENT' 'COMMA' '_LIST'
      '_ELEMENT' -> 'VAR'
      '_ELEMENT' -> 'VARTREE_BR'
      '_FLATLIST' -> 'VAR'
      '_FLATLIST' -> 'VAR' 'COMMA' '_FLATLIST'
    """

    class ParseErrors(Exception):

        """Exception class to represent a collection of parse errors.

        Instances of this class have two attributes, `errors` and `tree`.
        `errors` is a list of tuples, each describing one error.
        Each tuple consists of the first input token which could not
        be processed and the list of grammar symbols which were allowed
        at this point.
        `tree` is a "repaired" parse tree which might be used for further
        error checking, or `None` if no repair was possible.
        """

        def __init__(self, errors, tree):
            msg = "%d parse errors"%len(errors)
            Exception.__init__(self, msg)
            self.errors = errors
            self.tree = tree

    terminals = [ 'COMMA', 'LBRACE', 'RBRACE', 'VAR' ]
    _transparent = [ '_ELEMENT', '_FLATLIST', '_LIST' ]
    EOF = Unique('EOF')
    S = Unique('S')

    _halting_state = 17
    _reduce = {
        (4, EOF): ('VARTREE', 3), (5, EOF): ('VARTREE', 1),
        (8, 'COMMA'): ('VARTREE_BR', 3), (8, 'RBRACE'): ('VARTREE_BR', 3),
        (9, 'RBRACE'): ('_LIST', 1), (11, 'RBRACE'): ('_LIST', 3),
        (12, 'COMMA'): ('_ELEMENT', 1), (12, 'RBRACE'): ('_ELEMENT', 1),
        (13, 'COMMA'): ('_ELEMENT', 1), (13, 'RBRACE'): ('_ELEMENT', 1),
        (14, EOF): ('_FLATLIST', 1), (16, EOF): ('_FLATLIST', 3)
    }
    _goto = {
        (0, 'VARTREE'): 1, (0, '_FLATLIST'): 5, (2, 'VARTREE_BR'): 13,
        (2, '_ELEMENT'): 9, (2, '_LIST'): 3, (6, 'VARTREE_BR'): 13,
        (6, '_ELEMENT'): 9, (6, '_LIST'): 7, (10, 'VARTREE_BR'): 13,
        (10, '_ELEMENT'): 9, (10, '_LIST'): 11, (15, '_FLATLIST'): 16
    }
    _shift = {
        (0, 'LBRACE'): 2, (0, 'VAR'): 14, (1, EOF): 17, (2, 'LBRACE'): 6,
        (2, 'VAR'): 12, (3, 'RBRACE'): 4, (6, 'LBRACE'): 6, (6, 'VAR'): 12,
        (7, 'RBRACE'): 8, (9, 'COMMA'): 10, (10, 'LBRACE'): 6, (10, 'VAR'): 12,
        (14, 'COMMA'): 15, (15, 'VAR'): 14
    }

    def __init__(self, max_err=None, errcorr_pre=4, errcorr_post=4):
        """Create a new parser instance.

        The constructor arguments are all optional, they control the
        handling of parse errors: `max_err` can be given to bound the
        number of errors reported during one run of the parser.
        `errcorr_pre` controls how many tokens before an invalid token
        the parser considers when trying to repair the input.
        `errcorr_post` controls how far beyond an invalid token the
        parser reads when evaluating the quality of an attempted
        repair.
        """
        self.max_err = max_err
        self.m = errcorr_pre
        self.n = errcorr_post

    @staticmethod
    def leaves(tree):
        """Iterate over the leaves of a parse tree.

        This function can be used to reconstruct the input from a
        parse tree.
        """
        if tree[0] in Parser.terminals:
            yield tree
        else:
            for x in tree[1:]:
                for t in Parser.leaves(x):
                    yield t

    def _parse(self, input, stack, state):
        """Internal function to construct a parse tree.

        'Input' is the input token stream, 'stack' is the inital stack
        and 'state' is the inital state of the automaton.

        Returns a 4-tuple (done, count, state, error).  'done' is a
        boolean indicationg whether parsing is completed, 'count' is
        number of successfully shifted tokens, and 'error' is None on
        success or else the first token which could not be parsed.
        """
        read_next = True
        count = 0
        while state != self._halting_state:
            if read_next:
                try:
                    lookahead = input.next()
                except StopIteration:
                    return (False,count,state,None)
                read_next = False
            token = lookahead[0]

            if (state,token) in self._shift:
                stack.append((state,lookahead))
                state = self._shift[(state,token)]
                read_next = True
                count += 1
            elif (state,token) in self._reduce:
                X,n = self._reduce[(state,token)]
                if n > 0:
                    state = stack[-n][0]
                    tree = [ X ]
                    for s in stack[-n:]:
                        if s[1][0] in self._transparent:
                            tree.extend(s[1][1:])
                        else:
                            tree.append(s[1])
                    tree = tuple(tree)
                    del stack[-n:]
                else:
                    tree = (X,)
                stack.append((state,tree))
                state = self._goto[(state,X)]
            else:
                return (False,count,state,lookahead)
        return (True,count,state,None)

    def _try_parse(self, input, stack, state):
        count = 0
        while state != self._halting_state and count < len(input):
            token = input[count][0]

            if (state,token) in self._shift:
                stack.append(state)
                state = self._shift[(state,token)]
                count += 1
            elif (state,token) in self._reduce:
                X,n = self._reduce[(state,token)]
                if n > 0:
                    state = stack[-n]
                    del stack[-n:]
                stack.append(state)
                state = self._goto[(state,X)]
            else:
                break
        return count

    def parse(self, input):
        """Parse the tokens from `input` and construct a parse tree.

        `input` must be an interable over tuples.  The first element
        of each tuple must be a terminal symbol of the grammar which
        is used for parsing.  All other element of the tuple are just
        copied into the constructed parse tree.

        If `input` is invalid, a ParseErrors exception is raised.
        Otherwise the function returns the parse tree.
        """
        errors = []
        input = chain(input, [(self.EOF,)])
        stack = []
        state = 0
        while True:
            done,_,state,lookahead = self._parse(input, stack, state)
            if done:
                break

            expect = [ t for s,t in self._reduce.keys()+self._shift.keys()
                       if s == state ]
            errors.append((lookahead, expect))
            if self.max_err is not None and len(errors) >= self.max_err:
                raise self.ParseErrors(errors, None)

            queue = []
            def split_input(m, stack, lookahead, input, queue):
                for s in stack:
                    for t in self.leaves(s[1]):
                        queue.append(t)
                        if len(queue) > m:
                            yield queue.pop(0)
                queue.append(lookahead)
            in2 = split_input(self.m, stack, lookahead, input, queue)
            stack = []
            done,_,state,lookahead = self._parse(in2, stack, 0)
            m = len(queue)
            for i in range(0, self.n):
                try:
                    queue.append(input.next())
                except StopIteration:
                    break

            def vary_queue(queue, m):
                for i in range(m-1, -1, -1):
                    for t in self.terminals:
                        yield queue[:i]+[(t,)]+queue[i:]
                    if queue[i][0] == self.EOF:
                        continue
                    for t in self.terminals:
                        if t == queue[i]:
                            continue
                        yield queue[:i]+[(t,)]+queue[i+1:]
                    yield queue[:i]+queue[i+1:]
            best_val = len(queue)-m+1
            best_queue = queue
            for q2 in vary_queue(queue, m):
                pos = self._try_parse(q2, [ s[0] for s in stack ], state)
                val = len(q2) - pos
                if val < best_val:
                    best_val = val
                    best_queue = q2
                    if val == len(q2):
                        break
            if best_val >= len(queue)-m+1:
                raise self.ParseErrors(errors, None)
            input = chain(best_queue, input)

        tree = stack[0][1]
        if errors:
            raise self.ParseErrors(errors, tree)
        return tree