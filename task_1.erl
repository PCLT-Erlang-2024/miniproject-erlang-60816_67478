-module(task_1).
-export([start/2, produce/3, consume/1, pipeline_handler/2]).

-record(package, {id}).

start(PipelinesNum, PackagesNum) ->
  start(PipelinesNum, PackagesNum , 1).
start(PipelinesNum, _, Count) when Count > PipelinesNum -> ok;
start(PipelinesNum, PackagesNum, Count) when PipelinesNum >= Count ->
  Consumer = spawn(fun() -> consume(Count) end),
  Pipeline = spawn(fun() -> pipeline_handler(Consumer, Count) end),
  spawn(fun() -> produce(Pipeline, Count, PackagesNum) end),
  start(PipelinesNum, PackagesNum, Count + 1).


pipeline_handler(Consumer, PipelineId) ->
  receive
    Package when is_record(Package, package) ->
      Consumer ! Package,
      pipeline_handler(Consumer, PipelineId);
    stop ->
      io:format("Pipeline_~p is closed. No more packages.~n", [PipelineId]),
      Consumer ! stop;
    _ ->
      io:format("Invalid msg received in Pipeline_~p.~n", [PipelineId]),
      pipeline_handler(Consumer, PipelineId)
  end.

produce(Pipeline, PipelineId, PackageNum) ->
  produce(Pipeline, PipelineId, PackageNum, 1).

produce(Pipeline, PipelineId, PackageNum, Id) when PackageNum >= Id ->
  Package = #package{id = Id},
  Pipeline ! Package,
  io:format("Package_~p send to pipeline_~p .~n", [Id, PipelineId]),
  produce(Pipeline, PipelineId, PackageNum, Id + 1);

produce(Pipeline, _, _, _) ->
  Pipeline ! stop.



consume(PipelineId) ->
  receive
    Package when is_record(Package, package) ->
      io:format("Package_~p consumed in pipeline_~p .~n", [Package#package.id, PipelineId]),
      consume(PipelineId);
    stop ->
      io:format("Pipeline_~p consumer is closed. No more packages.~n", [PipelineId]);
    _ ->
      io:format("Invalid msg received in Pipeline_~p consumer.~n", [PipelineId]),
      consume(PipelineId)
  end.
