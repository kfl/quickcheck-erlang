%%%
%%% QuckCheck example, checking properties of the dict module
%%%
%%% Created by Ken Friis Larsen <kflarsen@diku.dk>

-module(dict_eqc).
-include_lib("eqc/include/eqc.hrl").
-compile(export_all).


% not a good function for checking dict:fetch_keys, because it consider 0 and 0.0 equal make your own
no_duplicates(Lst) ->
    length(Lst) =:= length(lists:usort(Lst)).

nub ([]) ->
    [];
nub ([X|XS]) ->
    [X | nub([Y || Y <- XS,
                   Y =/= X])].

no_duplicates2(Lst) ->
    length(Lst) =:= length(nub(Lst)).


prop_unique_keys() ->
    ?FORALL(D,dict(),
	    no_duplicates2(dict:fetch_keys(eval(D)))).

dict() ->
    dict_2().

dict_0() ->
    ?LAZY(
       oneof([dict:new(),
              ?LET({K,V,D},{key(), value(), dict_0()},
                   dict:store(K,V,D))])
      ).

dict_1() ->
    ?LAZY(
       oneof([{call,dict,new,[]},
              ?LETSHRINK([D],[dict_1()],
                         {call,dict,store,[key(),value(),D]})])
      ).

dict_2() ->
    ?LAZY(
       frequency([{1,{call,dict,new,[]}},
                  {4,?LETSHRINK([D],[dict_2()],
                                {call,dict,store,[key(),value(),D]})}])
      ).


key() ->
    oneof([int(),real(),atom()]).

value() ->
    key().

atom() ->
    elements([a,b,c,d,bart]).


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
