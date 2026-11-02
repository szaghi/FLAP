#!/usr/bin/env python3
"""Expose a FLAP program as a tool for an agent, from its --schema (standard library only).

An adapter lives outside the program: FLAP describes and validates, this file translates.
  flap_tool.py PROGRAM                    the tool definition: name, description, JSON Schema of the input
  flap_tool.py PROGRAM '{"--steps": 5}'   the command line of a call, validated by the program itself with --check
A long run should be submitted by the caller, not by the tool: this adapter never runs the program for real.
"""
import json
import os
import subprocess
import sys


def read_schema(program):
    """Read the description of a program."""
    out = subprocess.run([program, "--schema"], capture_output=True, text=True, check=True).stdout
    return json.loads(out)


def describe(schema):
    """Turn the description into a tool definition: options only, as a JSON Schema object."""
    properties, required = {}, []
    for option in schema["options"]:
        value = dict(option["value"])
        value["description"] = option["help"]
        properties[option["switch"]] = value
        if option["required"]:
            required.append(option["switch"])
    return {
        "name": schema["program"]["name"],
        "description": schema["program"]["description"],
        "input_schema": {"type": "object", "properties": properties, "required": required},
    }


def command_line(program, call):
    """Turn the input of a call into a command line; a flag takes no value, a list its items."""
    argv = [program]
    for switch, value in call.items():
        if value is True:
            argv.append(switch)
        elif isinstance(value, list):
            argv += [switch] + [str(item) for item in value]
        elif value is not False:
            argv += [switch, str(value)]
    return argv


def main():
    program = sys.argv[1]
    schema = read_schema(program)
    if len(sys.argv) == 2:
        print(json.dumps(describe(schema), indent=2))
        return 0
    argv = command_line(program, json.loads(sys.argv[2]))
    env = dict(os.environ)
    if schema["capabilities"]["error_format_env"]:
        env[schema["capabilities"]["error_format_env"]] = "json"
    check = subprocess.run([program, "--check"] + argv[1:], capture_output=True, text=True, env=env)
    print("command:", " ".join(argv))
    print("verdict:", check.stdout.strip())
    for line in check.stderr.splitlines():
        print("error:", json.loads(line)["message"])
    return check.returncode


if __name__ == "__main__":
    sys.exit(main())
