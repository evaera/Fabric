<div align="center">
	<br>
	<img src="https://i.eryn.io/2045/fabric.svg" alt="Fabric" height="140" />
	<br><br>
	<a href="https://discord.gg/Heyvvnd"><img src="https://img.shields.io/discord/425800792679645204.svg?label=discord" /></a>
</div>

Fabric provides infrastructure for representing the state of *things* in your game.

Fabric is currently experimental, and has not seen an initial release yet. Getting closer to that point every day!

## Features
- Safely encapsulate state and behaviors with "units"
- Easy cross-unit communication
- Only make changes to the world when relevant data changes
- [Hot reloading](https://i.eryn.io/2045/4sPsRGdA.mp4): make changes to your code and see them update immediately in game, no need to stop and replay.
- Automatic replication and networked events
- Client prediction of server state changes
- Create new instances declaratively with Roact ([Fabric + Roact = ❤️](https://i.eryn.io/2045/pYNXQain.png))
- Easy integration with CollectionService tags
- Built-in support for distribution of batched updates ([before](https://i.eryn.io/2047/2020-11-22_01-34-54.mp4) and [after](https://i.eryn.io/2047/2020-11-22_01-33-23.mp4))
## Principles

- Provide infrastructure for representing game state (things, not services).
- State is represented by lots of small units which can be attached to *anything*.
- Facilitate state sharing in a generic and consistent way that eliminates the need for many small manager services. Services can directly affect the state of the things they need to change without needing to go through an ancillary service that manages that state.
  - For example: Instead of two services needing to talk to the WalkSpeedManager service, they can instead both provide the same unit on the player which knows how to manage the walk speed.
- Units have layers.
  - Imagine each unit as a stack of transparent sheets of paper. Each page only contains the data that its author cares about. Then, to read the data in the unit, you look down at the stack. Newer layers override old data, but if the author of that page left that section blank, it falls through to the page below, all the way to the bottom page, which could contain default data.
  - This is how units work in Fabric. Each unit can have multiple layers at a time which when combined by Fabric form the final data. You can then add a callback to do something whenever there's new data on each unit.
  - This gives us multiple advantages:
    - It's now impossible to run into this scenario: Service A adds a unit to a thing, then Service B adds the same unit to that thing, which effectively did nothing. But now Service B removes that unit, but Service A still wants that unit there. With Fabric, Service B would have just removed its *layer*, not the entire unit. Which means that the unit still exists so long as one layer does.
- Units are more than just data. They can have their own behavior and can emit events. This is a natural way to think about and model problems that are primarily reacting to state changes.
- Fabric isn't an ECS (yet, anyway). Units provide functionality to react to state changes, but don't have any special machinery to facilitate updating on fixed intervals or in response to external events. Because of the way Fabric stores state, it would be possible to create an additional library on top of Fabric that provides "System" functionality, and that might be something that happens in the future.
- The same unit can exist on the server and the client. Fabric can handle replicating data from the server to the client in order to keep things in sync.
  - Fabric (will) also support replicated network events per-unit.
  - Fabric (will) also support only replicating a subset of the unit's data to the client by optionally white-listing keys of the unit data.
- Streaming first. Fabric only sends the client data that it needs. The client can request to subscribe to and unsubscribe from server-side units.
- Units can create other units. Fabric (will) provide an easy way to, based on the data of this unit, create another unit by transforming the data of this unit.
  - For example, this allows us to create many small, focused units, and then create higher-level units that could provide many units. 
  - Think about this: maybe you have a unit to track a damage-over-time effect on the player which deals some amount of damage to their health bar every few seconds. You could then build on that, creating a "Bleeding" unit, that in addition to creating a visual effect, also provides the "damage-over-time" unit instead of having to reimplement that behavior. This creates a nice pattern encouraging code reuse and reducing coupling.
- Units can be attached to *other units*. This might sound a bit crazy at first, but this gives us a nice way to manage data *about* the unit without intermingling it with the data *of* the unit.
  - For example, attaching the "Replicated" unit to any other unit will tell Fabric that you want this unit to also exist on the client.
- Fabric is extendible. Fabric exposes events which allow extensions to be created while keeping the core functionality focused and simple. For example, network replication and CollectionService tags are implemented as included extensions.
  - Planned included extensions:
    - Facilitate units communicating with events in a way that's statically configurable. This means that a Studio plugin would be able to be created, which for example allows you to connect a part with a Button unit to a part with a Door unit. The Button "press" event could be connected to the door's "open" method.

<small>Is this confusing? Please tell me in the [#fabric Discord channel](https://discord.gg/Heyvvnd) in my server. If you don't get it, you're probably not alone - let me know what I need to clarify!</small>
