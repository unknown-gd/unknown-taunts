### User-friendly and simple API to create, play and control taunts, dances and any other player sequences.
By default addon does not contain animations from Custom Taunt, you can install them individually, check out this collection: [uTaunt](https://steamcommunity.com/workshop/filedetails/?id=3161525439)

## Features
- **High Performance** - addon has a very low hardware requirements.
- **Simple** - users have access to one small menu with all sequences.
- **Extensibility** - other developers can expand the list of available sequences.
- **Reliable** - all sequences are synchronized both on server and client, implemented work with network and PVS.
- **Co-Dancing** - addon supports creating co-dances, as an example we have 2 dances from MMD ( Custom Taunt ).
- **Support** - addon will receive all necessary patches and updates during the year.

### Commands
- **utaunts** - *opens/closes UI, as well as stops current sequence if it is running.*
- **utaunt** - *executes the sequence specified by first argument or stops current sequence if nothing is specified.*

## Where is Lua code?
Written in [Yuescript](https://github.com/pigpigyyy/Yuescript), compiled Lua code can be found in [releases](https://github.com/PrikolMen/unknown-taunts/releases) and [lua branch](https://github.com/PrikolMen/unknown-taunts/tree/lua), or you can compile it yourself using compiled [Yuescript Compiler](https://github.com/pigpigyyy/Yuescript/releases/latest).

## Docs

### Server Functions
- `boolean` uTaunt.Start( `Player` ply, `string` sequenceName, `boolean` force, `float` cycle, `Vector` startOrigin, `Angle` startAngles )
- `boolean` uTaunt.Join( `Player` ply, `Player` dancingPlayer )
- `boolean` uTaunt.Stop( `Player` ply )

### Shared Functions
- `table` uTaunt.FindSequences( `Entity` entity, `string` pattern )
- `float` uTaunt.GetCycle( `Player` ply, `int` sequenceID, `float` startTime )
- `float` uTaunt.GetStartTime( `Player` ply ) - returns start time point in CurTime.
- `boolean` uTaunt.IsPlayingTaunt( `Player` ply )
- `boolean` uTaunt.IsValidTauntingPlayer( `Player` ply )

### Server Hooks
- GM:PlayerStoppedUnknownTaunt( `Player` ply, `string` sequenceName )
- GM:PlayerShouldUnknownTaunt( `Player` ply, `int` sequenceID )
- GM:PlayerStartUnknownTaunt( `Player` ply, `string` sequenceName, `float` duration )

### Client Hooks
- GM:AllowUnknownTauntMenu( `Player` ply )
- GM:UnknownTauntMenuSetup( `Player` ply, `function` add )
- GM:AllowUnknownTaunt( `Player` ply, `string` sequenceName, `string` categoryTitle )
