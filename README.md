# Stack Machine Interpreter

A simple stack-based virtual machine written in assembly, supporting basic arithmetic operations, stack manipulation, and input handling.

## Overview

This project implements a stack-based virtual machine that can perform arithmetic and stack operations. It handles input, parses commands, and executes them, while providing error handling for various runtime conditions.

## Table of Contents

- [Features](#features)
- [Data Layout](#data-layout)
- [Memory Sections](#memory-sections)
- [Command Implementations](#command-implementations)
- [Stack Operations](#stack-operations)
- [Error Messages](#error-messages)
- [Usage](#Usage(Example))

## Features

- **Arithmetic Operations**: `add`, `sub`, `mul`, `div`
- **Stack Operations**: `dup`, `pop`
- **Program Control**: `exit`

## Data Layout

- **Stack Size**: 512 bytes
- **Input Buffer Size**: 128 bytes

## Memory Sections

- **Commands**: Function pointers, mnemonics, and operand counts.
- **Stack**: Space for the VM stack.
- **Input Buffer**: Space for standard input.
- **Mnemonics**: Literal strings for each command.
- **Errors**: Various runtime error messages.

## Command Implementations

- **Arithmetic**:
    - `add`, `sub`, `mul`, `div`
- **Stack**:
    - `dup`, `pop`
- **Control**:
    - `exit`

## Stack Operations

- **Peek**: `stack_peek`
- **Pop**: `stack_pop`

## Error Messages

- `unknown instruction`
- `insufficient stack`
- `stack overflow`
- `stdin is empty`
- `stdin overflow`
- `missing operand`
- `unexpected char`
- `too many operands`

## Usage(Example)
- add 5 5
- sub 2
- mul 3
- pop
- pop
- exit
'5+5=10->2-10=(-8)->(-8)*3=(-24)'
