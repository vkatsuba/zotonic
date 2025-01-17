%% @author Marc Worrell <marc@worrell.nl>
%% @copyright 2009-2017 Marc Worrell
%% @doc Template access for access control functions and state

%% Copyright 2009-2017 Marc Worrell
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(m_acl).
-author("Marc Worrell <marc@worrell.nl").

-behaviour(zotonic_model).

%% interface functions
-export([
    m_get/3
]).

-include_lib("zotonic.hrl").

-define(is_action(A), A =:= <<"use">> orelse A =:= <<"admin">> orelse A =:= <<"view">>
    orelse A =:= <<"delete">> orelse A =:= <<"update">> orelse A =:= <<"insert">>
    orelse A =:= <<"link">>).

-spec m_get( list(), zotonic_model:opt_msg(), z:context()) -> zotonic_model:return().
m_get([ <<"user">> | Rest ], _Msg, Context) -> {ok, {z_acl:user(Context), Rest}};
m_get([ <<"is_admin">> | Rest ], _Msg, Context) -> {ok, {z_acl:is_admin(Context), Rest}};
m_get([ <<"is_read_only">> | Rest ], _Msg, Context) -> {ok, {z_acl:is_read_only(Context), Rest}};

% Check if current user is allowed to perform an action on some object
m_get([ Action, Object | Rest ], _Msg, Context) when ?is_action(Action) ->
    {ok, {is_allowed(Action, Object, Context), Rest}};
m_get([ <<"is_allowed">>, Action, Object | Rest ], _Msg, Context) when ?is_action(Action) ->
    {ok, {is_allowed(Action, Object, Context), Rest}};

% Check if an authenticated (default acl setttings) is allowed to perform an action on some object
m_get([ <<"authenticated">>, Action, Object | Rest ], _Msg, Context) when ?is_action(Action) ->
    {ok, {is_allowed_authenticated(Action, Object, Context), Rest}};
m_get([ <<"authenticated">>, <<"is_allowed">>, Action, Object | Rest ], _Msg, Context)  when ?is_action(Action) ->
    {ok, {is_allowed_authenticated(Action, Object, Context), Rest}};

% Error, unknown lookup.
m_get(Vs, _Msg, _Context) ->
    ?LOG_INFO("Unknown ~p lookup: ~p", [?MODULE, Vs]),
    {error, unknown_path}.

is_allowed(Action, Object, Context) when ?is_action(Action) ->
    try
        ActionAtom = erlang:binary_to_existing_atom(Action, utf8),
        Object1 = maybe_atom(Object),
        z_acl:is_allowed(ActionAtom, Object1, Context)
    catch
        error:badarg -> false
    end.

is_allowed_authenticated(Action, Object, Context) ->
    try
        ActionAtom = erlang:binary_to_existing_atom(Action, utf8),
        Context1 = case z_notifier:first(#acl_context_authenticated{}, Context) of
                        undefined -> Context;
                        Ctx -> Ctx
                   end,
        Object1 = maybe_atom(Object),
        z_acl:is_allowed(ActionAtom, Object1, Context1)
    catch
        error:badarg -> false
    end.


maybe_atom(<<>>) ->
    undefined;
maybe_atom(<<C, _/binary>> = B) when C >= $0, C =< $9 ->
    % Assume some integer or resource name
    B;
maybe_atom(B) when is_binary(B) ->
    try
        binary_to_existing_atom(B, utf8)
    catch
        _:_ -> B
    end;
maybe_atom(V) ->
    V.

