import os
from pathlib import Path
from subprocess import CompletedProcess
from unittest.mock import ANY, Mock, call, patch

from pytest import MonkeyPatch

import nixos_rebuild as n
import nixos_rebuild.services as s

from .helpers import get_qualified_name


@patch.dict(os.environ, {}, clear=True)
@patch("os.execve", autospec=True)
@patch(get_qualified_name(n.nix.run_wrapper, n.nix), autospec=True)
@patch(get_qualified_name(s.nix.build), autospec=True)
def test_reexec(
    mock_build: Mock, mock_run: Mock, mock_execve: Mock, monkeypatch: MonkeyPatch
) -> None:
    mock_run.return_value = CompletedProcess([], 0, stdout="")

    monkeypatch.setattr(s, "EXECUTABLE", "nixos-rebuild-ng")
    argv = ["/path/bin/nixos-rebuild-ng", "switch", "--no-flake"]
    args, _ = n.parse_args(argv)
    mock_build.return_value = Path("/path")

    grouped_nix_args = n.models.GroupedNixArgs(
        build_flags={"build": True},
        common_flags={"common": True},
        copy_flags={"copy": True},
        flake_eval_flags={"flake_eval": True},
        flake_build_flags={"flake_build": True},
    )
    result = s.reexec(argv, args, n.models.Action.SWITCH, grouped_nix_args)
    mock_build.assert_has_calls(
        [
            call(
                s.NIXOS_REBUILD_ATTR,
                n.models.BuildAttr(ANY, ANY),
                {"build": True, "no_out_link": True},
            )
        ]
    )
    # do not exec if there is no new version
    mock_execve.assert_not_called()
    # classic (non-flake) builds never build the system alongside
    # nixos-rebuild, so there's nothing to hand back
    assert result is None

    mock_build.return_value = Path("/path/new")

    s.reexec(argv, args, n.models.Action.SWITCH, grouped_nix_args)
    # exec in the new version successfully
    mock_execve.assert_called_once_with(
        Path("/path/new/bin/nixos-rebuild-ng"),
        ["/path/bin/nixos-rebuild-ng", "switch", "--no-flake"],
        {s.NIXOS_REBUILD_REEXEC_ENV: "1"},
    )

    mock_execve.reset_mock()
    mock_execve.side_effect = [OSError("BOOM"), None]

    s.reexec(argv, args, n.models.Action.SWITCH, grouped_nix_args)
    # exec in the previous version if the new version fails
    mock_execve.assert_any_call(
        Path("/path/bin/nixos-rebuild-ng"),
        ["/path/bin/nixos-rebuild-ng", "switch", "--no-flake"],
        {s.NIXOS_REBUILD_REEXEC_ENV: "1"},
    )


@patch.dict(os.environ, {}, clear=True)
@patch("os.execve", autospec=True)
@patch(get_qualified_name(s.nix.build_flake_many), autospec=True)
def test_reexec_flake(
    mock_build: Mock, mock_execve: Mock, monkeypatch: MonkeyPatch
) -> None:
    """When building locally from a flake, `nixos-rebuild` and the system
    closure are built together, in a single Nix evaluation."""
    monkeypatch.setattr(s, "EXECUTABLE", "nixos-rebuild-ng")
    argv = ["/path/bin/nixos-rebuild-ng", "switch", "--flake"]
    args, _ = n.parse_args(argv)
    mock_build.return_value = (Path("/path"), Path("/system/path"))

    grouped_nix_args = n.models.GroupedNixArgs(
        build_flags={"build": True},
        common_flags={"common": True},
        copy_flags={"copy": True},
        flake_eval_flags={"flake_eval": True},
        flake_build_flags={"flake_build": True},
    )
    result = s.reexec(argv, args, n.models.Action.SWITCH, grouped_nix_args)
    mock_build.assert_called_once_with(
        [s.NIXOS_REBUILD_ATTR, "config.system.build.toplevel"],
        n.models.Flake(ANY, ANY),
        {"flake_build": True, "flake_eval": True, "no_link": True},
    )
    # do not exec if there is no new version
    mock_execve.assert_not_called()
    # the system closure was already built alongside nixos-rebuild, so the
    # caller doesn't need to build it again
    assert result == Path("/system/path")

    mock_build.return_value = (Path("/path/new"), Path("/system/path/new"))

    result = s.reexec(argv, args, n.models.Action.SWITCH, grouped_nix_args)
    # exec in the new version successfully
    mock_execve.assert_called_once_with(
        Path("/path/new/bin/nixos-rebuild-ng"),
        ["/path/bin/nixos-rebuild-ng", "switch", "--flake"],
        {s.NIXOS_REBUILD_REEXEC_ENV: "1"},
    )
    # a newer nixos-rebuild is taking over, so it's in charge of (re-)building
    # the system itself
    assert result is None

    mock_execve.reset_mock()
    mock_execve.side_effect = [OSError("BOOM"), None]

    s.reexec(argv, args, n.models.Action.SWITCH, grouped_nix_args)
    # exec in the previous version if the new version fails
    mock_execve.assert_any_call(
        Path("/path/bin/nixos-rebuild-ng"),
        ["/path/bin/nixos-rebuild-ng", "switch", "--flake"],
        {s.NIXOS_REBUILD_REEXEC_ENV: "1"},
    )


@patch.dict(os.environ, {}, clear=True)
@patch("os.execve", autospec=True)
@patch(get_qualified_name(s.nix.build_flake), autospec=True)
def test_reexec_flake_rollback_not_combined(
    mock_build: Mock, mock_execve: Mock, monkeypatch: MonkeyPatch
) -> None:
    """`--rollback` has no system build to combine with, so `reexec()` falls
    back to only building `nixos-rebuild` itself, like before."""
    monkeypatch.setattr(s, "EXECUTABLE", "nixos-rebuild-ng")
    argv = ["/path/bin/nixos-rebuild-ng", "switch", "--flake", "--rollback"]
    args, _ = n.parse_args(argv)
    mock_build.return_value = Path("/path")

    grouped_nix_args = n.models.GroupedNixArgs(
        build_flags={"build": True},
        common_flags={"common": True},
        copy_flags={"copy": True},
        flake_eval_flags={"flake_eval": True},
        flake_build_flags={"flake_build": True},
    )
    result = s.reexec(argv, args, n.models.Action.SWITCH, grouped_nix_args)
    mock_build.assert_called_once_with(
        s.NIXOS_REBUILD_ATTR,
        n.models.Flake(ANY, ANY),
        {"flake_build": True, "flake_eval": True, "no_link": True},
    )
    mock_execve.assert_not_called()
    assert result is None


@patch.dict(os.environ, {}, clear=True)
@patch("os.execve", autospec=True)
@patch(get_qualified_name(s.nix.build_flake), autospec=True)
def test_reexec_flake_build_host_not_combined(
    mock_build: Mock, mock_execve: Mock, monkeypatch: MonkeyPatch
) -> None:
    """`--build-host` builds the system remotely, so `reexec()` falls back to
    only building `nixos-rebuild` itself locally, like before."""
    monkeypatch.setattr(s, "EXECUTABLE", "nixos-rebuild-ng")
    argv = [
        "/path/bin/nixos-rebuild-ng",
        "switch",
        "--flake",
        "--build-host",
        "foo@bar",
    ]
    args, _ = n.parse_args(argv)
    mock_build.return_value = Path("/path")

    grouped_nix_args = n.models.GroupedNixArgs(
        build_flags={"build": True},
        common_flags={"common": True},
        copy_flags={"copy": True},
        flake_eval_flags={"flake_eval": True},
        flake_build_flags={"flake_build": True},
    )
    result = s.reexec(argv, args, n.models.Action.SWITCH, grouped_nix_args)
    mock_build.assert_called_once_with(
        s.NIXOS_REBUILD_ATTR,
        n.models.Flake(ANY, ANY),
        {"flake_build": True, "flake_eval": True, "no_link": True},
    )
    mock_execve.assert_not_called()
    assert result is None


@patch.dict(os.environ, {s.NIXOS_REBUILD_REEXEC_ENV: "1"}, clear=True)
@patch("os.execve", autospec=True)
@patch(get_qualified_name(s.nix.build_flake), autospec=True)
def test_reexec_skip_if_already_reexec(mock_build: Mock, mock_execve: Mock) -> None:
    argv = ["/path/bin/nixos-rebuild-ng", "switch", "--flake"]
    args, _ = n.parse_args(argv)
    mock_build.return_value = Path("/path")

    grouped_nix_args = n.models.GroupedNixArgs(
        build_flags={"build": True},
        common_flags={"common": True},
        copy_flags={"copy": True},
        flake_eval_flags={"flake_eval": True},
        flake_build_flags={"flake_build": True},
    )
    result = s.reexec(argv, args, n.models.Action.SWITCH, grouped_nix_args)
    mock_build.assert_not_called()
    mock_execve.assert_not_called()
    assert result is None
