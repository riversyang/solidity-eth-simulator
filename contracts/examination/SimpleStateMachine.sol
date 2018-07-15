pragma solidity ^0.4.24;

contract SimpleStateMachine {
    enum States { S0, S1, S2, S3 }

    States public state = States.S0;

    modifier atState(States _state) {
        require(_state == state, "Function cannot be called at this time.");
        _;
    }

    function f1() public atState(States.S0) {
        state = States.S1;
    }

    function f2() public atState(States.S1) {
        state = States.S2;
    }

    function f3() public atState(States.S1) {
        state = States.S3;
    }

    function f4() public atState(States.S2) {
        state = States.S3;
    }

    function f5() public atState(States.S3) {
        state = States.S0;
    }
}