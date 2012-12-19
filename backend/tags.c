#include "urweb/urweb.h"

uw_Basis_string uw_Tags_unsafeHtml(uw_context ctx, uw_Basis_string x) {
    return x; // XXX I hope this is safe, do we need to realloc?
}
