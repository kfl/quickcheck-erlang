-module(meal).
-include_lib("eqc/include/eqc.hrl").
-compile(export_all).


prop_too_much_dairy() ->
    ?FORALL(Food, meal(), dairy_count(Food) == 0).

dairy_count(L) ->
    length([X || X <- L, is_dairy(X)]).

is_dairy(cheesesticks) -> true;
is_dairy(lasagna) -> true;
is_dairy(icecream) -> true;
is_dairy(milk) -> true;
is_dairy(_) -> false.

meal() ->
    ?LETSHRINK([Appetizer, Drink, Entree, Desert],
               [elements([soup, salad, cheesesticks]),
                elements([coffee, tea, milk, water, juice]),
                elements([lasagna, tofu, steak]),
                elements([cake, chocolate, icecream])],
               [Appetizer, Drink, Entree, Desert]).
