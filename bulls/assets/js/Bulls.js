import React, { useState, useEffect } from 'react';
import 'milligram';

import "../css/bulls.css"

import { ch_join, ch_push,
    ch_login, ch_reset, ch_addUser, ch_observer, ch_player, ch_ready, ch_notReady } from './socket';

function Controls({guess, reset}) {
    // WARNING: State in a nested component requires
    // careful thought.
    // If this component is ever unmounted (not shown
    // in a render), the state will be lost.
    // The default choice should be to put all state
    // in your root component.
    const [text, setText] = useState("");

    function keyDown(ev) {
        if (ev.key === "Enter") {
            guess(text);
        }
        else if (ev.key === "Backspace") {
            setText(text.slice(0,-1));
        }
        else {
            setText(text.concat(ev.key));
        }
    }

    return (
        <div className="row">
            <div className="column">
                <p>
                    <input type="text"
                           value={text}
                           onKeyDown={keyDown} />
                </p>
            </div>
            <div className="column">
                <p>
                    <button onClick={() => guess(text)}>Guess</button>
                </p>
            </div>
            <div className="column">
                <p>
                    <button onClick={reset}>
                        Reset
                    </button>
                </p>
            </div>
        </div>
    );
}

function reset() {
    ch_reset();
}

function validGuess(guess) {
    let nums = /^[0-9]+$/;
    let guessSet = new Set();
    if (guess.length !== 4) {
        return false;
    }
    if (!guess.match(nums)) {
        return false;
    }
    for (let i = 0; i < guess.length; i++) {
        if (guessSet.has(guess[i])) {
            return false;
        }
        else {
            guessSet.add(guess[i]);
        }
    }
    return true;
}

//Switch User to Observer
function switchToObserver(name) {
    ch_observer({user: name});
}

//Switch User To Player
function switchToPlayer(name) {
    ch_player({user: name});
}

function ready(name) {
    ch_ready({user: name});
}

function notReady(name) {
    ch_notReady({user: name});
}

function TheGame({state}) {
    let {name, observers, players, game_started, view, winLoss} = state;

    const [text, setText] = useState("");

    function guess(text) {
        // Inner function isn't a render function
        if (validGuess(text)) {
            ch_push({letter: text, username: name});
        }
        else {
            alert("bad guess");
        }
    }

    function GameButtons({reset,guess,name,players,game_started}) {
        if (game_started && players.includes(name)) {
            return (
                <div className = "row">
                    <Controls reset={reset} guess={guess} />
                </div>
            );
        }
        else {
            return (
                <div></div>
            );
        }
    }

    function ReadyButtons({name,players}) {
        if (players.includes(name) && !game_started) {
            return (
                <div className = "column">
                    <button onClick={() => ready(name)}>Ready</button>
                    <button onClick={() => notReady(name)}>Not Ready</button>
                </div>
            );
        }
        else {
            return (
                <div></div>
            );
        }
    }

    function PlayerObserverButtons({name,game_started}) {
        if (!game_started) {
            return (
                <div className = "column">
                    <button onClick={() => switchToObserver(name)}>Observer</button>
                    <button onClick={() => switchToPlayer(name)}>Player</button>
                </div>
            );
        }
        else {
            return (
                <div></div>
            );
        }
    }

    return (
        <div>
            <div>
                <p id="game-text">Welcome to Cows and Bulls! You are trying to guess a 4 digit number, which does not contain
                    repeated digits. When you enter a game you are automatically made an observer. To join the
                    game, select the player button. After everyone who has selected player also selects 'ready',
                    the game will begin. Each round you type in your 4 digit guess and hit enter. After every
                    player has guessed the game will reveal everyone's guesses and how many Cows + Bulls they have.
                    A Bull is a correct digit in the correct spot, and a Cow is a correct digit but in the wrong spot.
                    The system will not allow you to make any guesses which are not 4 numerical digits or which contain
                    repeated digits. A win loss count is shown to keep track of multiple rounds. Good luck!</p>
            </div>
            <div className = "row">
                <div className = "column">
                    <p className="box">Your Name: {name}</p>
                    <p className="box">Observers: {observers.join(" ")}</p>
                    <p className="box">Players: {players.join(", ")}</p>
                    <p className="box">GameStarted: {game_started.toString()}</p>
                </div>
                <div className = "column">
                    <ReadyButtons players={players} name={name} />
                </div>
                <div className = "column">
                    <PlayerObserverButtons name={name} game_started={game_started} />
                </div>
            </div>
            <div className = "row">
                <GameButtons reset={reset} guess={guess} name={name} players={players} game_started={game_started} />
            </div>
            <div className = "row">
                <div className = "column">
                    <p className= "output">{view.join("\n")}</p>
                </div>
                <div className = "column">
                    <p className= "output2">{winLoss.join("\n")}</p>
                </div>
            </div>
        </div>
    );
}

function Go(name, roomName) {
    ch_login(name, roomName);
    ch_addUser({name: name});
}

function Login() {

    const [name, setName] = useState("");

    return (
        <div className="row">
            <div className="column">
                <p>user name:</p>
                <input type="text"
                       value={name}
                       onChange={(ev) => setName(ev.target.value)} />
            </div>
            <div className="column">
                <p>room name:</p>
                <input type="text" id="roomName"/>
            </div>
            <div className="column">
                <button id="login-button" onClick={() => Go(name, document.getElementById("roomName").value)}>
                    Login
                </button>
            </div>
            <div className="row">
                <p id="login-text">Enter your username and a room name! If you enter the same room name as a
                    friend, you will be put in the same game!</p>
            </div>
        </div>
    );
}

function Bulls() {
    // render function,
    // should be pure except setState

    const [state, setState] = useState({
        name: "",
        observers: [],
        players: [],
        game_started: false,
        view: [],
        winLoss: [],
    });

    useEffect(() => {
        ch_join(setState, "1");
    });

    let body = null;

    if (state.name === "") {
        body = <Login />;
    }
    else {
        console.log(state["view"]);
        body = <TheGame state={state} />;
    }

    return (
        <div className="container">
            {body}
        </div>
    );
}

export default Bulls;
