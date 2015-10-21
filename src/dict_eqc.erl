%%%
%%% QuckCheck example, checking properties of the dict module
%%%
%%% Created by Ken Friis Larsen <kflarsen@diku.dk>

-module(dict_eqc).
-include_lib("eqc/include/eqc.hrl").
-compile(export_all).

% not a good function for checking dict:fetch_keys, because list:usort
% consider the values 0 and 0.0 to be equal, make your own.
no_duplicates(Lst) ->
    length(Lst) =:= length(lists:usort(Lst)).

prop_unique_keys() ->
    ?FORALL(D,dict(),
	    no_duplicates(dict:fetch_keys(eval(D)))).

dict() ->
    dict_3().

dict_0() ->
    ?LAZY(
       oneof([dict:new(),
	      ?LET({K,V,D},{key(), value(), dict_0()},
               dict:store(K,V,D))])
      ).

dict_1() ->
    ?LAZY(
       oneof([{call,dict,new,[]},
	      ?LET(D,dict_1(),
                     {call,dict,store,[key(),value(),D]})])
      ).

dict_2() ->
    ?LAZY(
       frequency([{1,{call,dict,new,[]}},
                  {4,?LET(D, dict_2(),
                          {call,dict,store,[key(),value(),D]})}])
      ).

dict_3() ->
    ?LAZY(
       frequency([{1,{call,dict,new,[]}},
                  {4,?LETSHRINK([D],[dict_3()],
                                {call,dict,store,[key(),value(),D]})}])
      ).




key() ->
    oneof([atom(), int(), real()]).

value() ->
    oneof([atom(), int(), real()]).

atom() ->
    elements([a,b,c,d]).


prop_measure() ->
    ?FORALL(D,dict(),
	    collect(length(dict:fetch_keys(eval(D))),true)).


model(Dict) ->
    lists:sort(dict:to_list(Dict)).

model_store(K,V,L) ->
    L1 = proplists:delete(K,L),
    lists:sort([{K,V}|L1]).


prop_store() ->
    ?FORALL({K,V,D}, {key(),value(),dict()},
            begin
                Dict = eval(D),
                equals(model(dict:store(K,V,Dict)),
                       model_store(K,V,model(Dict)))
            end).
