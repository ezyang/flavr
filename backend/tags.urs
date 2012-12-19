(* Can't write this because 'Name' is a reserved keyword
val meta : unit -> tag [Content = string, Name = string] head [] [] []
*)

(* Can't write this because 'Data-role' is not a valid label
val div : bodyTag ([Data-role = string] ++ boxAttrs)
*)

val unsafeHtml : ctx ::: {Unit} -> use ::: {Type} -> string -> xml ctx use []
