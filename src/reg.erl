%%% 
%%% QuckCheck example, testing the process registry
%%% Based on code from the paper "QuickCheck Testing for Fun and Profit"
%%% 
%%% Created : Oct 2011 by Ken Friis Larsen <kflarsen@diku.dk>

-module(reg).

-include_lib("eqc/include/eqc.hrl").
-include_lib("eqc/include/eqc_statem.hrl").

-compile(export_all).


%%% Correctness property

prop_registration() ->
  ?FORALL(Cmds,commands(?MODULE),
     begin
         {H,S,Res} = run_commands(?MODULE,Cmds),
         cleanup(S),
         ?WHENFAIL(io:format("History: ~p~nReason: ~p~n",[H, Res]),
                   pretty_commands(?MODULE, Cmds, {H, S, Res},
                                   aggregate(command_names(Cmds),
                                             Res==ok)))
     end).

%%% Model of states

-record(state,{pids,    % list of spawned pids
               regs}).  % list of registered names and pids

initial_state() ->
    #state{pids=[], regs=[]}.





%%% Command generator

%% command(S) ->
%%       oneof(
%%         [{call,erlang,register, [name(),pid(S)]},
%%          {call,erlang,unregister,[name()]},
%%          {call,?MODULE,spawn,[]},
%%          {call,erlang,whereis,[name()]}]).


%% Better implementation of command
command(S) ->
    oneof(
      [{call,erlang,register, [name(),pid(S)]} 
       || S#state.pids /= []] % small trick to make sure that pid(S) is only called when there are pids to choose
      ++
      [{call,erlang,unregister,[name()]}, % When neg testing instead use {call,?MODULE,unregister,[name()]},
       {call,?MODULE,spawn,[]},
       {call,erlang,whereis,[name()]}]).





pid(S) ->
    elements(S#state.pids).

names() ->
    [a,b,c,d].

name() -> 
    elements(names()).


%%% State transitions

next_state(S,V,{call,?MODULE,spawn,[]}) ->
    S#state{pids=[V | S#state.pids]};
next_state(S,_V,{call,_,register,[Name,Pid]}) ->
    S#state{regs=[{Name,Pid} | S#state.regs]};
next_state(S,_V,{call,_,unregister,[Name]}) ->
    S#state{regs = lists:keydelete(Name,1,S#state.regs)};
next_state(S,_V,_) ->
    S.

%%% Preconditions

%% For positive testing, uncomment the following clause
precondition(S,{call,_,unregister,[Name]}) -> 
    unregister_ok(S,Name);

precondition(_S,{call,_,_,_}) ->
    true.

%%% Postconditions

%% For negative testing, uncomment the following clause. 
%% REMEMBER to use the unregister function from this module in the command generator

% postcondition(S,{call,_,unregister,[Name]},Res) -> 
%     case Res of
%         {'EXIT',_} -> not unregister_ok(S,Name);
%         true       ->     unregister_ok(S,Name) 
%     end;

postcondition(_S,{call,_,_,_},_R) ->
    true.


% Operations for use in tests

unregister_ok(S,Name) -> 
    proplists:is_defined(Name,S#state.regs).


spawn() -> 
    spawn(fun() -> receive after 30000 -> ok end end).

register(Name,Pid) ->
    catch erlang:register(Name,Pid).

unregister(Name) ->
    catch erlang:unregister(Name).

stop(Pid) ->
    exit(Pid,kill),
    timer:sleep(1).

cleanup(S)->
    [catch erlang:unregister(N) || N<-names()], 
    [exit(P,kill) || P <- S#state.pids].
    
