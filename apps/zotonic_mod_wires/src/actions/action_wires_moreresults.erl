%% @author Arjan Scherpenisse <arjan@scherpenisse.net>
%% @copyright 2010-2021 Arjan Scherpenisse
%% @doc Get more results for search result

%% Copyright 2010-2021 Arjan Scherpenisse
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

-module(action_wires_moreresults).
-include_lib("zotonic_core/include/zotonic.hrl").
-export([render_action/4, event/2]).

render_action(TriggerId, TargetId, Args, Context) ->
    Result = case proplists:get_value(result, Args) of
        #search_result{} = M -> M
    end,
    SearchName = Result#search_result.search_name,
    PageLen = pagelen(Result, Result#search_result.search_args),
    case total(Result) < PageLen of
        true ->
            {"", z_render:add_script(["$(\"#", TriggerId, "\").remove();"], Context)};
        false ->
            NextPage = Result#search_result.page + 1,
            MorePageLen = proplists:get_value(pagelen, Args, PageLen),
            SearchProps = case Result#search_result.search_args of
                SPs when is_list(SPs) ->
                    proplists:delete(pagelen,
                        proplists:delete(page, SPs));
                SPs when is_map(SPs) ->
                    maps:without([ <<"page">>, <<"pagelen">> ], SPs)
            end,
            make_postback(SearchName, SearchProps, NextPage, PageLen, MorePageLen, Args, TriggerId, TargetId, Context)
    end.

total(#search_result{total=Total}) when is_integer(Total) ->
    Total;
total(#search_result{result=Result}) when is_list(Result) ->
    case proplists:get_value(ids, Result) of
        L when is_list(L) -> length(L);
        _ -> length(Result)
    end.


pagelen(#search_result{pagelen=PageLen}, _) when is_integer(PageLen) ->
    PageLen;
pagelen(_, #{ <<"pagelen">> := PageLen }) ->
    case z_convert:to_integer(PageLen) of
        undefined -> 20;
        PL -> PL
    end;
pagelen(_, SearchProps) when is_list(SearchProps) ->
    z_convert:to_integer(proplists:get_value(pagelen, SearchProps, 20));
pagelen(_, _) ->
    20.


%% @doc Show more results.
%% @spec event(Event, Context1) -> Context2
%% @todo Handle the "MorePageLen" argument correctly.
event(#postback{message={moreresults, SearchName, SearchProps, Page, PageLen, MorePageLen, Args}, trigger=TriggerId, target=TargetId}, Context) ->
    #search_result{result=Result} = case is_list(SearchProps) of
        true ->
            SearchProps1 = [
                {page, Page},
                {pagelen, PageLen}
                | SearchProps
            ],
            m_search:search({SearchName, SearchProps1}, Context);
        false ->
            z_search:search(SearchName, SearchProps, Page, PageLen, Context)
    end,
    Rows = case proplists:get_value(ids, Result) of
              undefined -> Result;
              X -> X
           end,
    Context1 = case length(Rows) < PageLen of
                   false ->
                        {JS, Ctx} = make_postback(SearchName, SearchProps, Page+1, PageLen, MorePageLen, Args, TriggerId, TargetId, Context),
                        RebindJS = case proplists:get_value(visible, Args) of
                           true ->
                               [ <<"z_on_visible('#">>, TriggerId, <<"', function() {">>, JS, <<"});">> ];
                           _ ->
                               ["$(\"#", TriggerId, "\").unbind(\"click\").click(function(){", JS, "; return false; });"]
                        end,
                        z_render:add_script(RebindJS, Ctx);
                   true ->
                        RemoveJS = ["$(\"#", TriggerId, "\").remove();"],
                        z_render:add_script(RemoveJS, Context)
               end,

    FirstRow = PageLen*(Page-1)+1,
    Template = proplists:get_value(template, Args),
    Html = case z_convert:to_bool(proplists:get_value(is_result_render,Args)) of
              true ->
                  Vars = [ {result, Rows}, {ids, lists:map(fun to_id/1, Rows)} | Args ],
                  z_template:render(Template, Vars, Context1);
              false ->
                  IsCatInclude = z_convert:to_bool(proplists:get_value(catinclude, Args)),
                  IdRows = lists:zip3(lists:map(fun to_id/1, Rows), Rows, lists:seq(FirstRow, FirstRow+length(Rows)-1)),
                  lists:map(fun({Id, ResultRow, RowNr}) ->
                                Vars = [
                                        {id, Id}, {result_row, ResultRow},
                                        {row, RowNr}, {is_first, RowNr == FirstRow}
                                        | Args
                                       ],
                                case IsCatInclude of
                                    true -> z_template:render({cat, Template}, Vars, Context1);
                                    false -> z_template:render(Template, Vars, Context1)
                                end
                            end,
                            IdRows)
                  end,
    z_render:appear_bottom(TargetId, Html, Context1).


to_id(Id) when is_integer(Id) -> Id;
to_id({Id,_}) when is_integer(Id) -> Id;
to_id({_,Id}) when is_integer(Id) -> Id;
to_id(T) when is_tuple(T) -> element(1, T);
to_id([{_,_}|_] = L) -> proplists:get_value(id, L);
to_id(M) when is_map(M) -> maps:get(id, M, undefined);
to_id(_) -> undefined.


make_postback(SearchName, SearchProps, Page, PageLen, MorePageLen, Args, TriggerId, TargetId, Context) ->
    Postback = {moreresults, SearchName, SearchProps, Page, PageLen, MorePageLen, Args},
    {PostbackJS, _PickledPostback} = z_render:make_postback(Postback, key, TriggerId, TargetId, ?MODULE, Context),
    {PostbackJS, Context}.
