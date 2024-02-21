### User-friendly and simple API to create, play and control taunts, dances and any other player sequences.
By default addon does not contain animations from Custom Taunt, you can install them individually, check out this collection: [uTaunt](https://steamcommunity.com/workshop/filedetails/?id=3161525439)

## Features
- **High Performance** - addon has a very low hardware requirements.
- **Simple** - users have access to one small menu with all sequences.
- **Extensibility** - other developers can expand the list of available sequences.
- **Reliable** - all sequences are synchronized both on server and client, implemented work with network and PVS.
- **Co-op Dances** - addon supports creating co-dances, as an example we have 2 dances from MMD ( Custom Taunt ).
- **Support** - addon will receive all necessary patches and updates during the year.

### Commands
- **utaunts** - *opens/closes UI, as well as stops current sequence if it is running.*
- **utaunt** - *executes the sequence specified by first argument or stops current sequence if nothing is specified.*

### ConVars
- **utaunt_coop_distance** - *Minimum required distance to join in a co-op taunt.*
- **utaunt_allow_weapon** - *Allow players to hold weapons in their hands while taunting.*
- **utaunt_collisions** - *Allow players to collide with each other while taunting.*

## Where is Lua code?
Written in [Yuescript](https://github.com/pigpigyyy/Yuescript), compiled Lua code can be found in [releases](https://github.com/PrikolMen/unknown-taunts/releases) and [lua branch](https://github.com/PrikolMen/unknown-taunts/tree/lua), or you can compile it yourself using compiled [Yuescript Compiler](https://github.com/pigpigyyy/Yuescript/releases/latest).

## Docs

### Server Functions
- `boolean` uTaunt.Start( `Player` ply, `string` sequenceName, `boolean` force, `float` cycle, `Vector` startOrigin, `Angle` startAngles ) - returns **true** if successful, otherwise **false**.
- `boolean` uTaunt.Join( `Player` ply, `Player` dancingPlayer ) - returns **true** if successful, otherwise **false**.
- `boolean` uTaunt.Stop( `Player` ply ) - returns **true** if successful, otherwise **false**.

### Shared Functions
- `table` uTaunt.FindSequences( `Entity` entity, `string` pattern ) - returns list with sequences data like `{ id = 0, name = "idle", duration = 1 }`.
- `float` uTaunt.GetCycle( `Player` ply, `int` sequenceID, `double` startTime ) - retuns sequence progress from 0 to 1 as **float**.
- `double` uTaunt.GetStartTime( `Player` ply ) - returns start time point in CurTime as **double**.
- `boolean` uTaunt.IsPlayingTaunt( `Player` ply ) - returns **true** if player is using uTaunt ( taunt at this time ).
- `boolean` uTaunt.IsValidTauntingPlayer( `Entity` entity ) - returns **true** if entity is a valid and alive player that using uTaunt ( taunt at this time ).

### Server Hooks
- GM:PlayerStoppedUnknownTaunt( `Player` ply, `string` sequenceName, `boolean` isFinished, `double` timeRemaining ) - called when a player's taunt was stopped.
- GM:PlayerShouldUnknownTaunt( `Player` ply, `int` sequenceID ) - if **false** is returned here, taunt will be blocked, if **true** then allowed.
- GM:PlayerStartUnknownTaunt( `Player` ply, `string` sequenceName, `double` duration ) - called when a player's taunt was started.

### Client Hooks
- GM:AllowUnknownTauntMenu( `Player` ply ) - if **false** is returned here, the taunt menu opening will be blocked.
- GM:UnknownTauntMenuSetup( `Player` ply, `function` add ) - called when taunt menu is being created, with '**add**' you can add more taunts and categories to that menu `add( "title", sequenceNamesList )`.
- GM:AllowUnknownTaunt( `Player` ply, `string` sequenceName, `string` categoryTitle ) - taunt filter for a player, if **false** is returned here, taunt will be hidden in the taunt menu.
