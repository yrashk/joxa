%% -*- mode: Erlang; fill-column: 80; comment-column: 76; -*-
-module(jxa_try).

-export([comp/3]).
-include_lib("joxa/include/joxa.hrl").

%%=============================================================================
%% Public API
%%=============================================================================
comp(Path0, Ctx0, ['__try', Expr, ['catch', [Type, Value], CatchExpr]])
  when is_atom(Type), is_atom(Value) ->
    Annots = jxa_annot:get_line(jxa_path:path(Path0),
                                jxa_ctx:annots(Ctx0)),
    {Ctx1, CerlExpr} = jxa_expression:comp(jxa_path:add(jxa_path:incr(Path0)),
                                           Ctx0,
                                           Expr),
    TryVar = cerl:ann_c_var([compiler_generated | Annots], joxa:gensym()),
    TypeVar = cerl:ann_c_var(Annots, Type),
    ValueVar = cerl:ann_c_var(Annots, Value),
    IgnoredVar = cerl:ann_c_var([compiler_generated | Annots], joxa:gensym()),

    Ctx2 =
        jxa_ctx:add_variable_to_scope(Type,
                                      jxa_ctx:add_variable_to_scope(Value,
                                                                    jxa_ctx:push_scope(Ctx1))),
    {Ctx3, CerlCatch} =
        jxa_expression:comp(jxa_path:add(jxa_path:incr(2, jxa_path:add(jxa_path:incr(2, Path0)))),
                            Ctx2, CatchExpr),
    {jxa_ctx:pop_scope(Ctx3),
     cerl:ann_c_try(Annots, CerlExpr,
                    [TryVar],
                    TryVar,
                    [TypeVar, ValueVar, IgnoredVar],
                    CerlCatch)};
comp(Path0, Ctx0, _) ->
    Idx = jxa_annot:get_idx(jxa_path:path(Path0),
                            jxa_ctx:annots(Ctx0)),
    ?JXA_THROW({invalid_try_expression, Idx}).


%%=============================================================================
%% Private API
%%=============================================================================
