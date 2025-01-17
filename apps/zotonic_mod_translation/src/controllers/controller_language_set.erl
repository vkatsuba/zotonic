%% @author Marc Worrell <marc@worrell.nl>
%% @copyright 2012-2021 Marc Worrell
%% @doc Set the language, redirect back to the page q.p

%% Copyright 2012-2021 Marc Worrell
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

-module(controller_language_set).
-author("Marc Worrell <marc@worrell.nl>").

-export([
    service_available/1,
    resource_exists/1,
    previously_existed/1,
    moved_temporarily/1,
    moved_permanently/1
]).

-include_lib("zotonic_core/include/zotonic.hrl").

service_available(Context) ->
    Context1 = z_context:set_noindex_header(Context),
    Context2 = z_context:set_nocache_headers(Context1),
    {true, Context2}.

resource_exists(Context) ->
    {false, Context}.

previously_existed(Context) ->
    {true, Context}.

-spec moved_temporarily(z:context()) -> {{true, binary()}, z:context()}.
moved_temporarily(Context) ->
    Context1 = mod_translation:set_user_language(z_context:get_q(<<"code">>, Context), Context),
    Page = z_context:get_q(<<"p">>, Context1),
    Location = case z_utils:is_empty(Page) of
                   true -> <<"/">>;
                   false -> Page
               end,
    Location1 = case z_context:is_site_url(Location, Context) of
        true -> Location;
        false -> <<"/">>
    end,
    AbsUrl = z_context:abs_url(
                    add_language(mod_translation:url_strip_language(Location1), Context1),
                    Context1),
    {{true, AbsUrl}, Context1}.

-spec moved_permanently(z:context()) -> {false, z:context()}.
moved_permanently(Context) ->
    {false, Context}.


-spec add_language(iodata(), z:context()) -> binary().
add_language(<<>>, Context) ->
    add_language(<<"/">>, Context);
add_language(Url, Context) ->
    iolist_to_binary([$/, z_convert:to_binary(z_context:language(Context)), Url]).

