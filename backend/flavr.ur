open Tags

table ingredient : { Id : int, Ingredient : string }
    PRIMARY KEY Id
    CONSTRAINT Ingredient UNIQUE Ingredient

table combo : { Id : int, IngredientId : int, With : string, Rating : int }
    PRIMARY KEY Id
    CONSTRAINT IngredientId FOREIGN KEY IngredientId REFERENCES ingredient(Id)

fun template b : page = <xml>
  <head>
    <link rel="stylesheet" type="text/css" href="http://code.jquery.com/mobile/1.2.0/jquery.mobile-1.2.0.min.css" />
    {unsafeHtml "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />"}
  </head>
  <body>
    {b}
  </body>
</xml>

fun main () : transaction page =
  return (template <xml><form>Ingredient: <textbox{#Ingredient}/> <submit value="Go" action={showTrampoline}/></form></xml>)

and showTrampoline r : transaction page =
  redirect (url (show r.Ingredient))

and show (ing : string) : transaction page =
  r <- queryX (SELECT combo.With FROM combo INNER JOIN ingredient ON ingredient.Id = combo.IngredientId WHERE ingredient.Ingredient = {[ing]})
         (fn r => <xml><li>{[r.Combo.With]}</li></xml>);
  return (template <xml>
    <h1>{[ing]}</h1>
    <ul>
      {r}
    </ul>
  </xml>)
