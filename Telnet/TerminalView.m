//
//  TerminalView.m
//  TerminalAppView
//
//  Created by Adam Eberbach on 14/08/11.
//  Copyright (c) 2011 Adam Eberbach. All rights reserved.
//

#import "TerminalView.h"
#import "NoAALabel.h"

@implementation TerminalView

@synthesize cursor;
@synthesize terminalRows;
@synthesize windowBegins;
@synthesize windowEnds;
@synthesize textIsBright;
@synthesize textIsDim;
@synthesize textIsUnderscore;
@synthesize textIsBlink;
@synthesize textIsReverse;
@synthesize textIsHidden;

- (void)scrollUp {

    NSMutableArray *topLine = [terminalRows objectAtIndex:0];
    [terminalRows removeObjectAtIndex:0];

    // alter top line to become bottom line, text is cleared and frame.origin.y set
    CGRect glyphFrame;
    CGFloat rowYOrigin = kGlyphHeight * (kTerminalRows - 1);
    for(UILabel* glyph in topLine) {
        glyph.text = nil;
        glyphFrame = glyph.frame;
        glyphFrame.origin.y = rowYOrigin;
        glyph.frame = glyphFrame;
    }
    // alter frame of all other lines so that they move up one line
    rowYOrigin = 0.f;
    for(NSMutableArray *array in terminalRows) {
        for(UILabel* glyph in array) {
            glyphFrame = glyph.frame;
            glyphFrame.origin.y = rowYOrigin;
            glyph.frame = glyphFrame;
        }
        rowYOrigin += kGlyphHeight;
    }
    // add the bottom line
    [terminalRows addObject:topLine];
}

- (void)cursorMoveToRow:(int)toRow toCol:(int)toCol {
    
    cursor.backgroundColor = [UIColor blackColor];
    cursor = [[terminalRows objectAtIndex:(toRow - 1)] objectAtIndex:(toCol - 1)];
    cursor.backgroundColor = [UIColor grayColor];
}

- (void)incrementCursorRow {

    
    if(cursor.row < kTerminalRows) {
        [self cursorMoveToRow:(cursor.row + 1) toCol:cursor.column];
    } 
    else {
       [self scrollUp];
    }
}

- (void)incrementCursorColumn {
    
    if(cursor.column < kTerminalColumns) {
        [self cursorMoveToRow:cursor.row toCol:cursor.column + 1];
    }
}

typedef enum _TelnetDataState {

    kTelnetDataStateRest = 0,
    kTelnetDataStateESC = 1,
    kTelnetDataStateCSI = 2
    
} TelnetDataState;

typedef enum _CommandState {
    kCommandStart,
    kCommandNumeric
} CommandState;

#if 0 // these are the chars to handle for ANSI command sequences
if (isdigit(c)) {
    if (term->esc_nargs <= ARGS_MAX) {
        if (term->esc_args[term->esc_nargs - 1] == ARG_DEFAULT)
            term->esc_args[term->esc_nargs - 1] = 0;
        term->esc_args[term->esc_nargs - 1] = 10 * term->esc_args[term->esc_nargs - 1] + c - '0';
    }
    term->termstate = SEEN_CSI;
} else if (c == ';') {
    if (term->esc_nargs < ARGS_MAX)
        term->esc_args[term->esc_nargs++] = ARG_DEFAULT;
    term->termstate = SEEN_CSI;
} else if (c < '@') {
    if (term->esc_query)
        term->esc_query = -1;
    else if (c == '?')
        term->esc_query = TRUE;
    else
        term->esc_query = c;
    term->termstate = SEEN_CSI;
} else
switch (ANSI(c, term->esc_query)) {
    case 'A':       /* CUU: move up N lines */
        move(term, term->curs.x,
             term->curs.y - def(term->esc_args[0], 1), 1);
        seen_disp_event(term);
        break;
    case 'e':		/* VPR: move down N lines */
        compatibility(ANSI);
        /* FALLTHROUGH */
    case 'B':		/* CUD: Cursor down */
        move(term, term->curs.x,
             term->curs.y + def(term->esc_args[0], 1), 1);
        seen_disp_event(term);
        break;
    case ANSI('c', '>'):	/* DA: report xterm version */
        compatibility(OTHER);
        /* this reports xterm version 136 so that VIM can
         use the drag messages from the mouse reporting */
        if (term->ldisc)
            ldisc_send(term->ldisc, "\033[>0;136;0c", 11, 0);
        break;
    case 'a':		/* HPR: move right N cols */
        compatibility(ANSI);
        /* FALLTHROUGH */
    case 'C':		/* CUF: Cursor right */ 
        move(term, term->curs.x + def(term->esc_args[0], 1),
             term->curs.y, 1);
        seen_disp_event(term);
        break;
    case 'D':       /* CUB: move left N cols */
        move(term, term->curs.x - def(term->esc_args[0], 1),
             term->curs.y, 1);
        seen_disp_event(term);
        break;
    case 'E':       /* CNL: move down N lines and CR */
        compatibility(ANSI);
        move(term, 0,
             term->curs.y + def(term->esc_args[0], 1), 1);
        seen_disp_event(term);
        break;
    case 'F':       /* CPL: move up N lines and CR */
        compatibility(ANSI);
        move(term, 0,
             term->curs.y - def(term->esc_args[0], 1), 1);
        seen_disp_event(term);
        break;
    case 'G':	      /* CHA */
    case '`':       /* HPA: set horizontal posn */
        compatibility(ANSI);
        move(term, def(term->esc_args[0], 1) - 1,
             term->curs.y, 0);
        seen_disp_event(term);
        break;
    case 'd':       /* VPA: set vertical posn */
        compatibility(ANSI);
        move(term, term->curs.x,
             ((term->dec_om ? term->marg_t : 0) +
              def(term->esc_args[0], 1) - 1),
             (term->dec_om ? 2 : 0));
        seen_disp_event(term);
        break;
    case 'H':	     /* CUP */
    case 'f':      /* HVP: set horz and vert posns at once */
        if (term->esc_nargs < 2)
            term->esc_args[1] = ARG_DEFAULT;
        move(term, def(term->esc_args[1], 1) - 1,
             ((term->dec_om ? term->marg_t : 0) +
              def(term->esc_args[0], 1) - 1),
             (term->dec_om ? 2 : 0));
        seen_disp_event(term);
        break;
    case 'J':       /* ED: erase screen or parts of it */
    {
        unsigned int i = def(term->esc_args[0], 0);
        if (i == 3) {
            /* Erase Saved Lines (xterm)
             * This follows Thomas Dickey's xterm. */
            term_clrsb(term);
        } else {
            i++;
            if (i > 3)
                i = 0;
            erase_lots(term, FALSE, !!(i & 2), !!(i & 1));
        }
    }
        term->disptop = 0;
        seen_disp_event(term);
        break;
    case 'K':       /* EL: erase line or parts of it */
    {
        unsigned int i = def(term->esc_args[0], 0) + 1;
        if (i > 3)
            i = 0;
        erase_lots(term, TRUE, !!(i & 2), !!(i & 1));
    }
        seen_disp_event(term);
        break;
    case 'L':       /* IL: insert lines */
        compatibility(VT102);
        if (term->curs.y <= term->marg_b)
            scroll(term, term->curs.y, term->marg_b,
				   -def(term->esc_args[0], 1), FALSE);
        seen_disp_event(term);
        break;
    case 'M':       /* DL: delete lines */
        compatibility(VT102);
        if (term->curs.y <= term->marg_b)
            scroll(term, term->curs.y, term->marg_b,
				   def(term->esc_args[0], 1),
				   TRUE);
        seen_disp_event(term);
        break;
    case '@':       /* ICH: insert chars */
        /* XXX VTTEST says this is vt220, vt510 manual says vt102 */
        compatibility(VT102);
        insch(term, def(term->esc_args[0], 1));
        seen_disp_event(term);
        break;
    case 'P':       /* DCH: delete chars */
        compatibility(VT102);
        insch(term, -def(term->esc_args[0], 1));
        seen_disp_event(term);
        break;
    case 'c':       /* DA: terminal type query */
        compatibility(VT100);
        /* This is the response for a VT102 */
        if (term->ldisc)
            ldisc_send(term->ldisc, term->id_string,
 				       strlen(term->id_string), 0);
        break;
    case 'n':       /* DSR: cursor position query */
        if (term->ldisc) {
            if (term->esc_args[0] == 6) {
				char buf[32];
				sprintf(buf, "\033[%d;%dR", term->curs.y + 1,
                        term->curs.x + 1);
				ldisc_send(term->ldisc, buf, strlen(buf), 0);
            } else if (term->esc_args[0] == 5) {
				ldisc_send(term->ldisc, "\033[0n", 4, 0);
            }
        }
        break;
    case 'h':       /* SM: toggle modes to high */
    case ANSI_QUE('h'):
        compatibility(VT100);
    {
        int i;
        for (i = 0; i < term->esc_nargs; i++)
            toggle_mode(term, term->esc_args[i],
					    term->esc_query, TRUE);
    }
        break;
    case 'i':		/* MC: Media copy */
    case ANSI_QUE('i'):
        compatibility(VT100);
    {
        if (term->esc_nargs != 1) break;
        if (term->esc_args[0] == 5 && *term->cfg.printer) {
            term->printing = TRUE;
            term->only_printing = !term->esc_query;
            term->print_state = 0;
            term_print_setup(term);
        } else if (term->esc_args[0] == 4 &&
                   term->printing) {
            term_print_finish(term);
        }
    }
        break;			
    case 'l':       /* RM: toggle modes to low */
    case ANSI_QUE('l'):
        compatibility(VT100);
    {
        int i;
        for (i = 0; i < term->esc_nargs; i++)
            toggle_mode(term, term->esc_args[i],
					    term->esc_query, FALSE);
    }
        break;
    case 'g':       /* TBC: clear tabs */
        compatibility(VT100);
        if (term->esc_nargs == 1) {
            if (term->esc_args[0] == 0) {
				term->tabs[term->curs.x] = FALSE;
            } else if (term->esc_args[0] == 3) {
				int i;
				for (i = 0; i < term->cols; i++)
				    term->tabs[i] = FALSE;
            }
        }
        break;
    case 'r':       /* DECSTBM: set scroll margins */
        compatibility(VT100);
        if (term->esc_nargs <= 2) {
            int top, bot;
            top = def(term->esc_args[0], 1) - 1;
            bot = (term->esc_nargs <= 1
				   || term->esc_args[1] == 0 ?
				   term->rows :
				   def(term->esc_args[1], term->rows)) - 1;
            if (bot >= term->rows)
				bot = term->rows - 1;
            /* VTTEST Bug 9 - if region is less than 2 lines
             * don't change region.
             */
            if (bot - top > 0) {
				term->marg_t = top;
				term->marg_b = bot;
				term->curs.x = 0;
				/*
				 * I used to think the cursor should be
				 * placed at the top of the newly marginned
				 * area. Apparently not: VMS TPU falls over
				 * if so.
				 *
				 * Well actually it should for
				 * Origin mode - RDB
				 */
				term->curs.y = (term->dec_om ?
                                term->marg_t : 0);
				seen_disp_event(term);
            }
        }
        break;
    case 'm':       /* SGR: set graphics rendition */
    {
        /* 
         * A VT100 without the AVO only had one
         * attribute, either underline or
         * reverse video depending on the
         * cursor type, this was selected by
         * CSI 7m.
         *
         * case 2:
         *  This is sometimes DIM, eg on the
         *  GIGI and Linux
         * case 8:
         *  This is sometimes INVIS various ANSI.
         * case 21:
         *  This like 22 disables BOLD, DIM and INVIS
         *
         * The ANSI colours appear on any
         * terminal that has colour (obviously)
         * but the interaction between sgr0 and
         * the colours varies but is usually
         * related to the background colour
         * erase item. The interaction between
         * colour attributes and the mono ones
         * is also very implementation
         * dependent.
         *
         * The 39 and 49 attributes are likely
         * to be unimplemented.
         */
        int i;
        for (i = 0; i < term->esc_nargs; i++) {
            switch (def(term->esc_args[i], 0)) {
                case 0:	/* restore defaults */
				    term->curr_attr = term->default_attr;
				    break;
                case 1:	/* enable bold */
				    compatibility(VT100AVO);
				    term->curr_attr |= ATTR_BOLD;
				    break;
                case 21:	/* (enable double underline) */
				    compatibility(OTHER);
                case 4:	/* enable underline */
				    compatibility(VT100AVO);
				    term->curr_attr |= ATTR_UNDER;
				    break;
                case 5:	/* enable blink */
				    compatibility(VT100AVO);
				    term->curr_attr |= ATTR_BLINK;
				    break;
                case 6:	/* SCO light bkgrd */
				    compatibility(SCOANSI);
				    term->blink_is_real = FALSE;
				    term->curr_attr |= ATTR_BLINK;
				    term_schedule_tblink(term);
				    break;
                case 7:	/* enable reverse video */
				    term->curr_attr |= ATTR_REVERSE;
				    break;
                case 10:      /* SCO acs off */
				    compatibility(SCOANSI);
				    if (term->cfg.no_remote_charset) break;
				    term->sco_acs = 0; break;
                case 11:      /* SCO acs on */
				    compatibility(SCOANSI);
				    if (term->cfg.no_remote_charset) break;
				    term->sco_acs = 1; break;
                case 12:      /* SCO acs on, |0x80 */
				    compatibility(SCOANSI);
				    if (term->cfg.no_remote_charset) break;
				    term->sco_acs = 2; break;
                case 22:	/* disable bold */
				    compatibility2(OTHER, VT220);
				    term->curr_attr &= ~ATTR_BOLD;
				    break;
                case 24:	/* disable underline */
				    compatibility2(OTHER, VT220);
				    term->curr_attr &= ~ATTR_UNDER;
				    break;
                case 25:	/* disable blink */
				    compatibility2(OTHER, VT220);
				    term->curr_attr &= ~ATTR_BLINK;
				    break;
                case 27:	/* disable reverse video */
				    compatibility2(OTHER, VT220);
				    term->curr_attr &= ~ATTR_REVERSE;
				    break;
                case 30:
                case 31:
                case 32:
                case 33:
                case 34:
                case 35:
                case 36:
                case 37:
				    /* foreground */
				    term->curr_attr &= ~ATTR_FGMASK;
				    term->curr_attr |=
					(term->esc_args[i] - 30)<<ATTR_FGSHIFT;
				    break;
                case 90:
                case 91:
                case 92:
                case 93:
                case 94:
                case 95:
                case 96:
                case 97:
				    /* aixterm-style bright foreground */
				    term->curr_attr &= ~ATTR_FGMASK;
				    term->curr_attr |=
					((term->esc_args[i] - 90 + 8)
                     << ATTR_FGSHIFT);
				    break;
                case 39:	/* default-foreground */
				    term->curr_attr &= ~ATTR_FGMASK;
				    term->curr_attr |= ATTR_DEFFG;
				    break;
                case 40:
                case 41:
                case 42:
                case 43:
                case 44:
                case 45:
                case 46:
                case 47:
				    /* background */
				    term->curr_attr &= ~ATTR_BGMASK;
				    term->curr_attr |=
					(term->esc_args[i] - 40)<<ATTR_BGSHIFT;
				    break;
                case 100:
                case 101:
                case 102:
                case 103:
                case 104:
                case 105:
                case 106:
                case 107:
				    /* aixterm-style bright background */
				    term->curr_attr &= ~ATTR_BGMASK;
				    term->curr_attr |=
					((term->esc_args[i] - 100 + 8)
                     << ATTR_BGSHIFT);
				    break;
                case 49:	/* default-background */
				    term->curr_attr &= ~ATTR_BGMASK;
				    term->curr_attr |= ATTR_DEFBG;
				    break;
                case 38:   /* xterm 256-colour mode */
				    if (i+2 < term->esc_nargs &&
                        term->esc_args[i+1] == 5) {
                        term->curr_attr &= ~ATTR_FGMASK;
                        term->curr_attr |=
					    ((term->esc_args[i+2] & 0xFF)
					     << ATTR_FGSHIFT);
                        i += 2;
				    }
				    break;
                case 48:   /* xterm 256-colour mode */
				    if (i+2 < term->esc_nargs &&
                        term->esc_args[i+1] == 5) {
                        term->curr_attr &= ~ATTR_BGMASK;
                        term->curr_attr |=
					    ((term->esc_args[i+2] & 0xFF)
					     << ATTR_BGSHIFT);
                        i += 2;
				    }
				    break;
            }
        }
        set_erase_char(term);
    }
        break;
    case 's':       /* save cursor */
        save_cursor(term, TRUE);
        break;
    case 'u':       /* restore cursor */
        save_cursor(term, FALSE);
        seen_disp_event(term);
        break;
    case 't': /* DECSLPP: set page size - ie window height */
        /*
         * VT340/VT420 sequence DECSLPP, DEC only allows values
         *  24/25/36/48/72/144 other emulators (eg dtterm) use
         * illegal values (eg first arg 1..9) for window changing 
         * and reports.
         */
        if (term->esc_nargs <= 1
            && (term->esc_args[0] < 1 ||
				term->esc_args[0] >= 24)) {
			    compatibility(VT340TEXT);
			    if (!term->cfg.no_remote_resize)
                    request_resize(term->frontend, term->cols,
                                   def(term->esc_args[0], 24));
			    deselect(term);
			} else if (term->esc_nargs >= 1 &&
                       term->esc_args[0] >= 1 &&
                       term->esc_args[0] < 24) {
			    compatibility(OTHER);
                
			    switch (term->esc_args[0]) {
                        int x, y, len;
                        char buf[80], *p;
                    case 1:
                        set_iconic(term->frontend, FALSE);
                        break;
                    case 2:
                        set_iconic(term->frontend, TRUE);
                        break;
                    case 3:
                        if (term->esc_nargs >= 3) {
                            if (!term->cfg.no_remote_resize)
                                move_window(term->frontend,
                                            def(term->esc_args[1], 0),
                                            def(term->esc_args[2], 0));
                        }
                        break;
                    case 4:
                        /* We should resize the window to a given
                         * size in pixels here, but currently our
                         * resizing code isn't healthy enough to
                         * manage it. */
                        break;
                    case 5:
                        /* move to top */
                        set_zorder(term->frontend, TRUE);
                        break;
                    case 6:
                        /* move to bottom */
                        set_zorder(term->frontend, FALSE);
                        break;
                    case 7:
                        refresh_window(term->frontend);
                        break;
                    case 8:
                        if (term->esc_nargs >= 3) {
                            if (!term->cfg.no_remote_resize)
                                request_resize(term->frontend,
                                               def(term->esc_args[2], term->cfg.width),
                                               def(term->esc_args[1], term->cfg.height));
                        }
                        break;
                    case 9:
                        if (term->esc_nargs >= 2)
                            set_zoomed(term->frontend,
                                       term->esc_args[1] ?
                                       TRUE : FALSE);
                        break;
                    case 11:
                        if (term->ldisc)
                            ldisc_send(term->ldisc,
                                       is_iconic(term->frontend) ?
                                       "\033[2t" : "\033[1t", 4, 0);
                        break;
                    case 13:
                        if (term->ldisc) {
                            get_window_pos(term->frontend, &x, &y);
                            len = sprintf(buf, "\033[3;%d;%dt", x, y);
                            ldisc_send(term->ldisc, buf, len, 0);
                        }
                        break;
                    case 14:
                        if (term->ldisc) {
                            get_window_pixels(term->frontend, &x, &y);
                            len = sprintf(buf, "\033[4;%d;%dt", y, x);
                            ldisc_send(term->ldisc, buf, len, 0);
                        }
                        break;
                    case 18:
                        if (term->ldisc) {
                            len = sprintf(buf, "\033[8;%d;%dt",
                                          term->rows, term->cols);
                            ldisc_send(term->ldisc, buf, len, 0);
                        }
                        break;
                    case 19:
                        /*
                         * Hmmm. Strictly speaking we
                         * should return `the size of the
                         * screen in characters', but
                         * that's not easy: (a) window
                         * furniture being what it is it's
                         * hard to compute, and (b) in
                         * resize-font mode maximising the
                         * window wouldn't change the
                         * number of characters. *shrug*. I
                         * think we'll ignore it for the
                         * moment and see if anyone
                         * complains, and then ask them
                         * what they would like it to do.
                         */
                        break;
                    case 20:
                        if (term->ldisc &&
                            term->cfg.remote_qtitle_action != TITLE_NONE) {
                            if(term->cfg.remote_qtitle_action == TITLE_REAL)
                                p = get_window_title(term->frontend, TRUE);
                            else
                                p = EMPTY_WINDOW_TITLE;
                            len = strlen(p);
                            ldisc_send(term->ldisc, "\033]L", 3, 0);
                            ldisc_send(term->ldisc, p, len, 0);
                            ldisc_send(term->ldisc, "\033\\", 2, 0);
                        }
                        break;
                    case 21:
                        if (term->ldisc &&
                            term->cfg.remote_qtitle_action != TITLE_NONE) {
                            if(term->cfg.remote_qtitle_action == TITLE_REAL)
                                p = get_window_title(term->frontend, FALSE);
                            else
                                p = EMPTY_WINDOW_TITLE;
                            len = strlen(p);
                            ldisc_send(term->ldisc, "\033]l", 3, 0);
                            ldisc_send(term->ldisc, p, len, 0);
                            ldisc_send(term->ldisc, "\033\\", 2, 0);
                        }
                        break;
			    }
			}
        break;
    case 'S':		/* SU: Scroll up */
        compatibility(SCOANSI);
        scroll(term, term->marg_t, term->marg_b,
               def(term->esc_args[0], 1), TRUE);
        term->wrapnext = FALSE;
        seen_disp_event(term);
        break;
    case 'T':		/* SD: Scroll down */
        compatibility(SCOANSI);
        scroll(term, term->marg_t, term->marg_b,
               -def(term->esc_args[0], 1), TRUE);
        term->wrapnext = FALSE;
        seen_disp_event(term);
        break;
    case ANSI('|', '*'): /* DECSNLS */
        /* 
         * Set number of lines on screen
         * VT420 uses VGA like hardware and can
         * support any size in reasonable range
         * (24..49 AIUI) with no default specified.
         */
        compatibility(VT420);
        if (term->esc_nargs == 1 && term->esc_args[0] > 0) {
            if (!term->cfg.no_remote_resize)
				request_resize(term->frontend, term->cols,
                               def(term->esc_args[0],
                                   term->cfg.height));
            deselect(term);
        }
        break;
    case ANSI('|', '$'): /* DECSCPP */
        /*
         * Set number of columns per page
         * Docs imply range is only 80 or 132, but
         * I'll allow any.
         */
        compatibility(VT340TEXT);
        if (term->esc_nargs <= 1) {
            if (!term->cfg.no_remote_resize)
				request_resize(term->frontend,
                               def(term->esc_args[0],
                                   term->cfg.width), term->rows);
            deselect(term);
        }
        break;
    case 'X':     /* ECH: write N spaces w/o moving cursor */
        /* XXX VTTEST says this is vt220, vt510 manual
         * says vt100 */
        compatibility(ANSIMIN);
    {
        int n = def(term->esc_args[0], 1);
        pos cursplus;
        int p = term->curs.x;
        termline *cline = scrlineptr(term->curs.y);
        
        if (n > term->cols - term->curs.x)
            n = term->cols - term->curs.x;
        cursplus = term->curs;
        cursplus.x += n;
        check_boundary(term, term->curs.x, term->curs.y);
        check_boundary(term, term->curs.x+n, term->curs.y);
        check_selection(term, term->curs, cursplus);
        while (n--)
            copy_termchar(cline, p++,
					      &term->erase_char);
        seen_disp_event(term);
    }
        break;
    case 'x':       /* DECREQTPARM: report terminal characteristics */
        compatibility(VT100);
        if (term->ldisc) {
            char buf[32];
            int i = def(term->esc_args[0], 0);
            if (i == 0 || i == 1) {
				strcpy(buf, "\033[2;1;1;112;112;1;0x");
				buf[2] += i;
				ldisc_send(term->ldisc, buf, 20, 0);
            }
        }
        break;
    case 'Z':		/* CBT */
        compatibility(OTHER);
    {
        int i = def(term->esc_args[0], 1);
        pos old_curs = term->curs;
        
        for(;i>0 && term->curs.x>0; i--) {
            do {
                term->curs.x--;
            } while (term->curs.x >0 &&
					 !term->tabs[term->curs.x]);
        }
        check_selection(term, old_curs, term->curs);
    }
        break;
    case ANSI('c', '='):      /* Hide or Show Cursor */
        compatibility(SCOANSI);
        switch(term->esc_args[0]) {
            case 0:  /* hide cursor */
			    term->cursor_on = FALSE;
			    break;
            case 1:  /* restore cursor */
			    term->big_cursor = FALSE;
			    term->cursor_on = TRUE;
			    break;
            case 2:  /* block cursor */
			    term->big_cursor = TRUE;
			    term->cursor_on = TRUE;
			    break;
        }
        break;
    case ANSI('C', '='):
        /*
         * set cursor start on scanline esc_args[0] and
         * end on scanline esc_args[1].If you set
         * the bottom scan line to a value less than
         * the top scan line, the cursor will disappear.
         */
        compatibility(SCOANSI);
        if (term->esc_nargs >= 2) {
            if (term->esc_args[0] > term->esc_args[1])
				term->cursor_on = FALSE;
            else
				term->cursor_on = TRUE;
        }
        break;
    case ANSI('D', '='):
        compatibility(SCOANSI);
        term->blink_is_real = FALSE;
        term_schedule_tblink(term);
        if (term->esc_args[0]>=1)
            term->curr_attr |= ATTR_BLINK;
        else
            term->curr_attr &= ~ATTR_BLINK;
        break;
    case ANSI('E', '='):
        compatibility(SCOANSI);
        term->blink_is_real = (term->esc_args[0] >= 1);
        term_schedule_tblink(term);
        break;
    case ANSI('F', '='):      /* set normal foreground */
        compatibility(SCOANSI);
        if (term->esc_args[0] >= 0 && term->esc_args[0] < 16) {
            long colour =
            (sco2ansicolour[term->esc_args[0] & 0x7] |
             (term->esc_args[0] & 0x8)) <<
            ATTR_FGSHIFT;
            term->curr_attr &= ~ATTR_FGMASK;
            term->curr_attr |= colour;
            term->default_attr &= ~ATTR_FGMASK;
            term->default_attr |= colour;
            set_erase_char(term);
        }
        break;
    case ANSI('G', '='):      /* set normal background */
        compatibility(SCOANSI);
        if (term->esc_args[0] >= 0 && term->esc_args[0] < 16) {
            long colour =
            (sco2ansicolour[term->esc_args[0] & 0x7] |
             (term->esc_args[0] & 0x8)) <<
            ATTR_BGSHIFT;
            term->curr_attr &= ~ATTR_BGMASK;
            term->curr_attr |= colour;
            term->default_attr &= ~ATTR_BGMASK;
            term->default_attr |= colour;
            set_erase_char(term);
        }
        break;
    case ANSI('L', '='):
        compatibility(SCOANSI);
        term->use_bce = (term->esc_args[0] <= 0);
        set_erase_char(term);
        break;
    case ANSI('p', '"'): /* DECSCL: set compat level */
        /*
         * Allow the host to make this emulator a
         * 'perfect' VT102. This first appeared in
         * the VT220, but we do need to get back to
         * PuTTY mode so I won't check it.
         *
         * The arg in 40..42,50 are a PuTTY extension.
         * The 2nd arg, 8bit vs 7bit is not checked.
         *
         * Setting VT102 mode should also change
         * the Fkeys to generate PF* codes as a
         * real VT102 has no Fkeys. The VT220 does
         * this, F11..F13 become ESC,BS,LF other
         * Fkeys send nothing.
         *
         * Note ESC c will NOT change this!
         */
        
        switch (term->esc_args[0]) {
            case 61:
			    term->compatibility_level &= ~TM_VTXXX;
			    term->compatibility_level |= TM_VT102;
			    break;
            case 62:
			    term->compatibility_level &= ~TM_VTXXX;
			    term->compatibility_level |= TM_VT220;
			    break;
                
            default:
			    if (term->esc_args[0] > 60 &&
                    term->esc_args[0] < 70)
                    term->compatibility_level |= TM_VTXXX;
			    break;
                
            case 40:
			    term->compatibility_level &= TM_VTXXX;
			    break;
            case 41:
			    term->compatibility_level = TM_PUTTY;
			    break;
            case 42:
			    term->compatibility_level = TM_SCOANSI;
			    break;
                
            case ARG_DEFAULT:
			    term->compatibility_level = TM_PUTTY;
			    break;
            case 50:
			    break;
        }
        
        /* Change the response to CSI c */
        if (term->esc_args[0] == 50) {
            int i;
            char lbuf[64];
            strcpy(term->id_string, "\033[?");
            for (i = 1; i < term->esc_nargs; i++) {
				if (i != 1)
				    strcat(term->id_string, ";");
				sprintf(lbuf, "%d", term->esc_args[i]);
				strcat(term->id_string, lbuf);
            }
            strcat(term->id_string, "c");
        }
#endif
        
#if 0 // these are the chars that must be handled in DEC mode (not SEEN_CSI)

case '7':		/* DECSC: save cursor */
compatibility(VT100);
save_cursor(term, TRUE);
break;
case '8':	 	/* DECRC: restore cursor */
compatibility(VT100);
save_cursor(term, FALSE);
seen_disp_event(term);
break;
case '=':		/* DECKPAM: Keypad application mode */
compatibility(VT100);
term->app_keypad_keys = TRUE;
break;
case '>':		/* DECKPNM: Keypad numeric mode */
compatibility(VT100);
term->app_keypad_keys = FALSE;
break;
case 'D':	       /* IND: exactly equivalent to LF */
compatibility(VT100);
if (term->curs.y == term->marg_b)
scroll(term, term->marg_t, term->marg_b, 1, TRUE);
else if (term->curs.y < term->rows - 1)
term->curs.y++;
term->wrapnext = FALSE;
seen_disp_event(term);
break;
case 'E':	       /* NEL: exactly equivalent to CR-LF */
compatibility(VT100);
term->curs.x = 0;
if (term->curs.y == term->marg_b)
scroll(term, term->marg_t, term->marg_b, 1, TRUE);
else if (term->curs.y < term->rows - 1)
term->curs.y++;
term->wrapnext = FALSE;
seen_disp_event(term);
break;
case 'M':	       /* RI: reverse index - backwards LF */
compatibility(VT100);
if (term->curs.y == term->marg_t)
scroll(term, term->marg_t, term->marg_b, -1, TRUE);
else if (term->curs.y > 0)
term->curs.y--;
term->wrapnext = FALSE;
seen_disp_event(term);
break;
case 'Z':	       /* DECID: terminal type query */
compatibility(VT100);
if (term->ldisc)
ldisc_send(term->ldisc, term->id_string,
           strlen(term->id_string), 0);
break;
case 'c':	       /* RIS: restore power-on settings */
compatibility(VT100);
power_on(term, TRUE);
if (term->ldisc)   /* cause ldisc to notice changes */
ldisc_send(term->ldisc, NULL, 0, 0);
if (term->reset_132) {
    if (!term->cfg.no_remote_resize)
        request_resize(term->frontend, 80, term->rows);
    term->reset_132 = 0;
}
term->disptop = 0;
seen_disp_event(term);
break;
case 'H':	       /* HTS: set a tab */
compatibility(VT100);
term->tabs[term->curs.x] = TRUE;
break;

case ANSI('8', '#'):	/* DECALN: fills screen with Es :-) */
compatibility(VT100);
{
    termline *ldata;
    int i, j;
    pos scrtop, scrbot;
    
    for (i = 0; i < term->rows; i++) {
        ldata = scrlineptr(i);
        for (j = 0; j < term->cols; j++) {
            copy_termchar(ldata, j,
					      &term->basic_erase_char);
            ldata->chars[j].chr = 'E';
        }
        ldata->lattr = LATTR_NORM;
    }
    term->disptop = 0;
    seen_disp_event(term);
    scrtop.x = scrtop.y = 0;
    scrbot.x = 0;
    scrbot.y = term->rows;
    check_selection(term, scrtop, scrbot);
}
break;

case ANSI('3', '#'):
case ANSI('4', '#'):
case ANSI('5', '#'):
case ANSI('6', '#'):
compatibility(VT100);
{
    int nlattr;
    
    switch (ANSI(c, term->esc_query)) {
        case ANSI('3', '#'): /* DECDHL: 2*height, top */
            nlattr = LATTR_TOP;
            break;
        case ANSI('4', '#'): /* DECDHL: 2*height, bottom */
            nlattr = LATTR_BOT;
            break;
        case ANSI('5', '#'): /* DECSWL: normal */
            nlattr = LATTR_NORM;
            break;
        default: /* case ANSI('6', '#'): DECDWL: 2*width */
            nlattr = LATTR_WIDE;
            break;
    }
    scrlineptr(term->curs.y)->lattr = nlattr;
}
break;
/* GZD4: G0 designate 94-set */
case ANSI('A', '('):
compatibility(VT100);
if (!term->cfg.no_remote_charset)
term->cset_attr[0] = CSET_GBCHR;
break;
case ANSI('B', '('):
compatibility(VT100);
if (!term->cfg.no_remote_charset)
term->cset_attr[0] = CSET_ASCII;
break;
case ANSI('0', '('):
compatibility(VT100);
if (!term->cfg.no_remote_charset)
term->cset_attr[0] = CSET_LINEDRW;
break;
case ANSI('U', '('): 
compatibility(OTHER);
if (!term->cfg.no_remote_charset)
term->cset_attr[0] = CSET_SCOACS; 
break;
/* G1D4: G1-designate 94-set */
case ANSI('A', ')'):
compatibility(VT100);
if (!term->cfg.no_remote_charset)
term->cset_attr[1] = CSET_GBCHR;
break;
case ANSI('B', ')'):
compatibility(VT100);
if (!term->cfg.no_remote_charset)
term->cset_attr[1] = CSET_ASCII;
break;
case ANSI('0', ')'):
compatibility(VT100);
if (!term->cfg.no_remote_charset)
term->cset_attr[1] = CSET_LINEDRW;
break;
case ANSI('U', ')'): 
compatibility(OTHER);
if (!term->cfg.no_remote_charset)
term->cset_attr[1] = CSET_SCOACS; 
break;
/* DOCS: Designate other coding system */
case ANSI('8', '%'):	/* Old Linux code */
case ANSI('G', '%'):
compatibility(OTHER);
if (!term->cfg.no_remote_charset)
term->utf = 1;
break;
case ANSI('@', '%'):
compatibility(OTHER);
if (!term->cfg.no_remote_charset)
term->utf = 0;
break;
}
#endif



typedef void (^CommandSequenceHandler)(NSArray *, TerminalView *term);

// H - cursor position
static void (^cursorAbsolutePosition)(NSArray *, TerminalView *) = ^(NSArray *numericValues, TerminalView *term) { 
    
    int targetRow = 1;
    int targetColumn = 1;
    
    if([numericValues count] == 2) {
        targetRow = [[numericValues objectAtIndex:0] intValue];
        targetColumn = [[numericValues objectAtIndex:1] intValue];
    }
    [term cursorMoveToRow:targetRow toCol:targetColumn];
};

// B - cursor move down
static void (^cursorMoveDown)(NSArray *, TerminalView *) = ^(NSArray *numericValues, TerminalView *term) { 
    
    int rows = [[numericValues objectAtIndex:0] intValue];
    for(int i = 0; i < rows; i++) {
        // this is wrong because screen should not scroll as a result of this
        [term incrementCursorRow];
    }
};

// m - set text attributes
static void (^setTextAttributes)(NSArray *, TerminalView *) = ^(NSArray *numericValues, TerminalView *term) { 

    for(NSNumber *number in numericValues) {
        int value = [number intValue];
        switch(value) {
            case kTextAtributeClear:
                term.textIsBright = NO;
                term.textIsDim = NO;
                term.textIsUnderscore = NO;
                term.textIsBlink = NO;
                term.textIsReverse = NO;
                term.textIsHidden = NO;
                
            case kTextAttributeBright:
                term.textIsBright = YES;
                term.textIsDim = NO;
                break;
            case kTextAttributeDim:
                term.textIsDim = YES;
                term.textIsBright = NO;
                break;
            case kTextAttributeUnderscore:
                term.textIsUnderscore = YES;
                break;
            case kTextAttributeBlink:
                term.textIsBlink = YES;
                break;
            case kTextAttributeReverse:
                term.textIsReverse = YES;
                break;
            case kTextAttributeHidden:
                term.textIsHidden = YES;
                break;
            default:
                break;
        }
    }
};

// r - set window
static void (^setWindow)(NSArray *, TerminalView *) = ^(NSArray *numericValues, TerminalView *term) { 
    term.windowBegins = [[numericValues objectAtIndex:0] intValue];
    term.windowEnds = [[numericValues objectAtIndex:1] intValue];
};

// J - erase in display ED
static void (^doClearLine)(NSArray *, TerminalView *) = ^(NSArray *numericValues, TerminalView *term) { 
    
    int argument;
    if([numericValues count] == 0)
        argument = 0;
    else
        argument = [[numericValues objectAtIndex:0] intValue];
    NSArray *columns;
    
    switch(argument) {
        case 0: // clear screen from cursor down
            // clear from cursor to end of line
            columns = [term.terminalRows objectAtIndex:(term.cursor.row - 1)];
            for(int i = term.cursor.column; i < kTerminalColumns; i++) {
                NoAALabel *glyph = [columns objectAtIndex:i];
                [glyph erase];
            }
            // then clear all rows below
            for(int i = term.cursor.row; i < kTerminalRows; i++) {
                NSArray *rowArray = [term.terminalRows objectAtIndex:(i - 1)];
                for(NoAALabel *glyph in rowArray) {
                    [glyph erase];
                }
            }
            break;
        case 1: // clear screen from cursor up
            // clear all rows above
            for(int i = 0; i < term.cursor.row; i++) {
                NSArray *rowArray = [term.terminalRows objectAtIndex:(i - 1)];
                for(NoAALabel *glyph in rowArray) {
                    [glyph erase];
                }
            }
            // then clear up to cursor
            columns = [term.terminalRows objectAtIndex:(term.cursor.row - 1)];
            for(int i = 0; i < term.cursor.column; i++) {
                NoAALabel *glyph = [columns objectAtIndex:i];
                [glyph erase];
            }
            break;
        case 2: // clear entire screen
            for(NSMutableArray *array in term.terminalRows) {
                for(NoAALabel* glyph in array) {
                    [glyph erase];
                }
            }
            break;
        default:
            break;
    }

};

- (void)processANSICommandSequence:(unsigned char *)sequence withLength:(int)len {
    
    NSString *commandIdentifier = [NSString string];
    NSMutableArray *numericValues = [NSMutableArray array];
    CommandState state = kCommandStart;
    int numeric;
    
    while(len--) {
        
        unsigned char d = *sequence++;
        switch(state) {
            case kCommandStart:
                if(d >= 060 && d <= 071) {
                    // starting a numeric sequence
                    state = kCommandNumeric;
                    numeric = d - 060;
                } else {
                    // process command 
                    commandIdentifier = [commandIdentifier stringByAppendingFormat:@"%c", d];
                }
                break;
            case kCommandNumeric:
                if(d >= 060 && d <= 071) {
                    // continuing a numeric sequence
                    numeric *= 10;
                    numeric += d - 060;
                } else if (d == ';') {
                    // a compound argument command. Add the numeric received so far to an array of
                    // values and clear the value for a possible next value
                    [numericValues addObject:[NSNumber numberWithInt:numeric]];
                    numeric = 0;
                    
                } else {
                    if(numeric > 0) {
                        [numericValues addObject:[NSNumber numberWithInt:numeric]];
                    }
                    commandIdentifier = [commandIdentifier stringByAppendingFormat:@"%c", d];
                    state = kCommandStart;
                }
                break;
        }
    }
    
    // leaving this loop implies that a command has ended. Are there any commands that remain ambiguous?
    CommandSequenceHandler handler = [commandSequenceHandlerDictionary objectForKey:commandIdentifier];
    if(handler != nil) {
        // need to pass the values accompanying this command and the terminal to operate on
        handler(numericValues, self);
    } else {
        NSLog(@"Unhandled ANSICommand: %@", commandIdentifier);
        if([numericValues count] > 0)
            NSLog(@"%@", numericValues);
    }
}

- (void)processDECCommandSequence:(unsigned char *)sequence withLength:(int)len {
    NSString *commandDebugString = [NSString string];
    
    while(len--) {
        commandDebugString = [commandDebugString stringByAppendingFormat:@"%c", *sequence++];
    }
    NSLog(@"DECCommand: %@", commandDebugString);
}

- (void)processCommandSequence:(NSData *)command {
    
    unsigned char * c = (unsigned char *)[command bytes];
    int len = [command length];
    
    if(*c++ != 033) {
        NSLog(@"command must start with ESC");
        return;
    }
    len--;
    
    if(*c == '[') {
        // eat the '['
        [self processANSICommandSequence:++c withLength:--len];
    } else {
        [self processDECCommandSequence:c withLength:len];
    }
}

- (void)processDataChunk {
    
    unsigned char *c = (unsigned char *)[dataForDisplay bytes];
    int len = [dataForDisplay length];
    TelnetDataState dataState = kTelnetDataStateRest;
    
    NSMutableData *command = [NSMutableData data];
    BOOL continuing = YES;
    
    while(len-- && continuing) {
        
        unsigned char d = *c++;
        
        switch(dataState) {
                
            case kTelnetDataStateRest: {

                // simplest case - not part of a command sequence, output a glyph
                if(d >= 32 && d <= 126) {
                    
                    UILabel *glyph = [[terminalRows objectAtIndex:(cursor.row - 1)] objectAtIndex:(cursor.column - 1)];
                    glyph.text = [NSString stringWithFormat:@"%c", d];
                    [self incrementCursorColumn];
//                    continuing = NO;
                    break;
                    
                // individual special characters
                } else if (d == 000) { // NUL (ignored)
                } else if (d == 005) { // ENQ transmit answerback
                } else if (d == 007) { // BEL bell sound
                } else if (d == 010) { // BS backspace
                } else if (d == 011) { // HT next horizontal tab stop or right margin if no more stops exist
                } else if (d == 012 || d == 013 || d == 014) { // LF, VT, FF line feed
                    [self incrementCursorRow];
                    continuing = NO;
                } else if (d == 015) { // CR carriage return
                    [self incrementCursorRow];
                    [self cursorMoveToRow:cursor.row toCol:1];
                    continuing = NO;
                } else if (d == 016) { // SQ invoke G1 character set
                } else if (d == 017) { // SI invoke G0 character set
                } else if (d == 021) { // XON resume transmission
                } else if (d == 023) { // XOFF pause transmission                    
                } else if (d == 033) { // ESC initiate control sequence
                    [command appendBytes:&d length:1];
                    dataState = kTelnetDataStateESC;
                } else if (d == 0177) { // ignored
                }
            }
            break;
                
            case kTelnetDataStateESC: {
                
                if (d == 0133) { // [ - enter CSI state
                    [command appendBytes:&d length:1];
                    dataState = kTelnetDataStateCSI;
                } else if (d == 033) { // ESC - discard all preceding control sequence construction, begin again
                    command = [NSMutableData dataWithBytes:&d length:1];
                } else if (d == 0104 || d == 0105 || d == 0115) { // D index, E newline, M reverse index
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0101 || d == 0102 || d == 060 || d == 061 || d == 062) { // A UK, B USASCII, 0 Special graphics, 1 alt ROM, 2 alt ROM special graphics
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                    
                } else if (d == 067 || d == 070) { // 7 save cursor, 8 restore cursor
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 030 || d == 032) { // CAN, SUB cancel current control sequence
                    command = nil;
                    continuing = NO;
                } else if (d == 050 || d == 051) { // ( G0 designator, ) G1 designator
                    [command appendBytes:&d length:1];
                } else {
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                }
            }
            break;

            case kTelnetDataStateCSI: {
                
                if (d == 033) { // ESC - discard all preceding control sequence construction, begin again
                    command = [NSMutableData dataWithBytes:&d length:1];
                } else if (d >= 060 && d <= 071) { // could be a digit giving a count for the command
                    [command appendBytes:&d length:1];
                } else if (d == 0101 || d == 0102 || d == 0103 || d == 0104) { // A up, B down, C left, D right
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0110) { // H set cursor position
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0154) { // l selectable modes
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0161) { // q load LEDs
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0170) { // x report terminal parameters
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0146) { // f horizontal and vertical position
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0162) { // r set top and bottom margins
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0057) { // / reset mode
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0150) { // h set mode
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0156) { // n status report
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0143) { // c what are you?
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 0155) { // m set character attributes
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                } else if (d == 073) { // ; - a compound command
                    [command appendBytes:&d length:1];
                } else if (d == 0112 || d == 0113) { // J line erase, K screen erase
                    [command appendBytes:&d length:1];
                    [self processCommandSequence:command];
                    continuing = NO;
                }
            }
            break;

        }
    }
    
    if(len > 0) {
        
        dataForDisplay = [NSMutableData dataWithBytes:c length:len];
        
        // more data to display, allow run loop to continue and return here
        [self performSelector:@selector(processDataChunk) withObject:nil afterDelay:0.0f];
    } else {
        dataForDisplay = nil;
    }
}

// display each of the bytes in the view advancing cursor position
- (void)displayData:(NSData *)data {
    
    if(dataForDisplay == nil)
        dataForDisplay = [data mutableCopy];
    else
        [dataForDisplay appendData:data];

    // processDataChunk is a method that can proceed with display until it should break,
    // e.g. to facilitate terminal animation or other ancient tricks.
    [self processDataChunk];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

        commandSequenceHandlerDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                            cursorMoveDown, @"B",
                                            cursorAbsolutePosition, @"H",
                                            doClearLine, @"J",
                                            setTextAttributes, @"m",
                                            setWindow, @"r",
                                            nil];
        terminalRows = [NSMutableArray array];
        NSMutableArray *terminalRow;
        CGFloat xPos;
        CGFloat yPos;
        int i, j;
        
        for(i = 1; i <= kTerminalRows; i++) {
            
            terminalRow = [NSMutableArray array];
            yPos = (CGFloat)(i * kGlyphHeight);
            
            for(j = 1; j <= kTerminalColumns; j++) {
                
                xPos = (CGFloat)(j * kGlyphWidth);
                
                NoAALabel *glyph = [[NoAALabel alloc] initWithFrame:CGRectMake(xPos, yPos, kGlyphWidth, kGlyphHeight)];
                glyph.font = [UIFont fontWithName:@"Courier New" size:kGlyphFontSize];
                glyph.textColor = [UIColor whiteColor];
                glyph.backgroundColor = [UIColor blackColor];
                glyph.text = nil;
                glyph.row = i;
                glyph.column = j;
                [terminalRow addObject:glyph];
                [self addSubview:glyph];
            }
            [terminalRows addObject:terminalRow];
        }
        
        CGRect selfFrame = self.frame;
        selfFrame.size.width = kGlyphWidth * (CGFloat)kTerminalColumns;
        selfFrame.size.height = kGlyphHeight * (CGFloat)kTerminalRows;
        self.frame = selfFrame;
        
        cursor = [[terminalRows objectAtIndex:0] objectAtIndex:0];
        cursor.backgroundColor = [UIColor grayColor];

        dataForDisplay = [[NSMutableData alloc] init];
    }
    return self;
}

@end
