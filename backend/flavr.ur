table ingredient : { IngredientId : int, Ingredient : string }
    PRIMARY KEY IngredientId
    CONSTRAINT Ingredient UNIQUE Ingredient

table combo : { ComboId : int, IngredientId : int, With : string, Rating : int }
    PRIMARY KEY ComboId

fun template b : page = <xml><body>{b}</body></xml>

fun main () : transaction page =
    return (template <xml><form>Ingredient: <textbox{#Ingredient}/> <submit value="Go" action={showTrampoline}/></form></xml>)
and showTrampoline r : transaction page =
    redirect (url (show r.Ingredient))
and show (ingredient : string) : transaction page =
    return (template <xml>{[ingredient]}</xml>)
