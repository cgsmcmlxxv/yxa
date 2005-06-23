%%%-------------------------------------------------------------------
%%% File    : yxa_config_erlang.erl
%%% Author  : Fredrik Thulin <ft@it.su.se>
%%% Descrip.: Config backend for default values.
%%%
%%% Created : 18 Jun 2005 by Fredrik Thulin <ft@it.su.se>
%%%-------------------------------------------------------------------
-module(yxa_config_default).

-behaviour(yxa_config).

-export([
	 init/1,
	 parse/1
	]).

%%--------------------------------------------------------------------
%% Include files
%%--------------------------------------------------------------------
-include("yxa_config.hrl").

%%--------------------------------------------------------------------
%% Records
%%--------------------------------------------------------------------
-record(yxa_config_default_state, {
	  defaults	%% dict(), our default values
	 }).


%%====================================================================
%% External functions
%%====================================================================


%%--------------------------------------------------------------------
%% Function: init([AppModule])
%%	     AppModule = atom(), Yxa application module
%% Descrip.: Initiates the configuration backend.
%% Returns : {ok, State} | ignore | {error, Msg}
%%           State = yxa_config_erlang_state record()
%%           Msg = string()
%%--------------------------------------------------------------------
init(AppModule) ->
    %% common defaults
    Dict1 = cfg_to_dict(?COMMON_DEFAULTS),

    %% application defaults
    Dict2 = init_get_app_dict(AppModule),

    %% Merge to left, meaning resolve duplicates in dicts by using the second value
    MergeLeft = fun(_K, _V1, V2) ->
			V2
		end,

    Dict = dict:merge(MergeLeft, Dict1, Dict2),

    {ok, #yxa_config_default_state{defaults = Dict}}.

init_get_app_dict(Application) ->
    %% APPLICATION_DEFAULTS looks like this :
    %% [{app1, Config}, {app2, Config}], get the right Config for Application
    case lists:keysearch(Application, 1, ?APPLICATION_DEFAULTS) of
	{value, {Application, Config}} when is_list(Config) ->
	    cfg_to_dict(Config);
	false ->
	    %% return empty dict when there is no application specific config
	    dict:new()
    end.

%%--------------------------------------------------------------------
%% Function: parse(State)
%%	     State = yxa_config_default_state record()
%% Descrip.: Return parsed config data.
%% Returns : {ok, Cfg} | {error, Msg}
%%           Cfg = yxa_config record()
%%           Msg = string()
%%--------------------------------------------------------------------
parse(State) when is_record(State, yxa_config_default_state) ->
    L1 = dict:to_list(State#yxa_config_default_state.defaults),
    %% turn all {Key, Value} tuples we get from dict:to_list() into
    %% the {Key, Value, ?MODULE} tuples that this function should return
    L2 = lists:map(fun({K, V}) ->
			   {K, V, ?MODULE}
		      end, L1),
    {ok, #yxa_cfg{entrys = L2}}.


%%====================================================================
%% Internal functions
%%====================================================================


cfg_to_dict(In) ->
    L = cfg_to_list(In, []),
    dict:from_list(L).

cfg_to_list([H | T], Res) when is_record(H, cfg_entry) ->
    This = {H#cfg_entry.key, H#cfg_entry.default},
    cfg_to_list(T, [This | Res]);
cfg_to_list([], Res) ->
    lists:reverse(Res).
