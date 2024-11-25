-module(task_2).
-export([start/4, produce/4, consume/2, pipeline_handler/2]).

-record(truck, {id, capacity, currentSize}).
-record(package, {id, size}).

start(PipelinesNum, PackagesNum, TruckCapacity, PkgMaxSize) ->
  start(PipelinesNum, PackagesNum, TruckCapacity, PkgMaxSize, 1).

start(PipelinesNum, _, _, _, Count) when Count > PipelinesNum -> ok;

start(PipelinesNum, PackagesNum, TruckCapacity, PkgMaxSize, Count) when PipelinesNum >= Count ->
  Consumer = spawn(fun() -> consume(Count, TruckCapacity) end),
  Pipeline = spawn(fun() -> pipeline_handler(Consumer, Count) end),
  spawn(fun() -> produce(Pipeline, Count, PackagesNum, PkgMaxSize) end),
  start(PipelinesNum, PackagesNum, TruckCapacity, PkgMaxSize, Count + 1).


pipeline_handler(Consumer, PipelineId) ->
  receive
    Package when is_record(Package, package) ->
      Consumer ! Package,
      pipeline_handler(Consumer, PipelineId);
    stop ->
      io:format("Pipeline_~p is closed. No more packages to send.~n", [PipelineId]),
      Consumer ! stop;
    _ ->
      io:format("Invalid msg received in Pipeline_~p.~n", [PipelineId]),
      pipeline_handler(Consumer, PipelineId)
  end.


produce(Pipeline, PipelineId, PackageNum, PkgMaxSize) ->
  produce(Pipeline, PipelineId, PackageNum,PkgMaxSize, 1).

produce(Pipeline, PipelineId, PackageNum, PkgMaxSize, Id) when PackageNum >= Id ->
  Size = rand:uniform(PkgMaxSize),
  Package = #package{id = Id, size = Size},
  Pipeline ! Package,
  io:format("Package_~p with size: ~p send to pipeline_~p .~n", [Id, Size, PipelineId]),
  produce(Pipeline, PipelineId, PackageNum, PkgMaxSize, Id + 1);

produce(Pipeline, _, _, _, _) ->
  Pipeline ! stop.

consume(PipelineId, TruckCapacity) ->
  Truck = #truck{id = 1, capacity = TruckCapacity, currentSize = 0},
  consume(PipelineId, Truck, TruckCapacity).

consume(PipelineId, Truck, TruckCapacity) ->
  receive
    Package when is_record(Package, package) ->
      case canLoad(Truck, Package#package.size) of
        false ->
          io:format("In Pipeline_~p: Truck_~p can not load package_~p, Creating a new one.~n", [PipelineId, Package#package.id, Truck#truck.id]),
          NewTruck = #truck{id = Truck#truck.id + 1, capacity = TruckCapacity, currentSize = 0},
          UpdatedTruck = addPackageToTruck(NewTruck, Package#package.size),
          io:format("In Pipeline_~p: Truck_~p loaded package_~p. CurrentSize: ~p/~p.~n",
            [PipelineId, UpdatedTruck#truck.id, Package#package.id, UpdatedTruck#truck.currentSize, TruckCapacity]),
          consume(PipelineId, UpdatedTruck, TruckCapacity);

        true ->
          UpdatedTruck = addPackageToTruck(Truck, Package#package.size),
          io:format("In Pipeline_~p: Truck_~p loaded package_~p. CurrentSize: ~p/~p.~n",
            [PipelineId, UpdatedTruck#truck.id, Package#package.id, UpdatedTruck#truck.currentSize, TruckCapacity]),
          consume(PipelineId, UpdatedTruck, TruckCapacity)
      end;
    stop ->
      io:format("Pipeline_~p consumer is closed. No more packages to receive.~n", [PipelineId]);
    _ ->
      io:format("Invalid msg received in Pipeline_~p consumer.~n", [PipelineId]),
      consume(PipelineId, Truck, TruckCapacity)
  end.


canLoad(Truck, PkgSize) ->
  Truck#truck.capacity >= Truck#truck.currentSize + PkgSize.

addPackageToTruck(Truck, PkgSize) ->
  Truck#truck{currentSize = Truck#truck.currentSize + PkgSize}.
