#!/usr/bin/env python3
"""
Auto-align markdown table columns.

Ensures all pipe characters in each table are at the same
column position across all rows (MD060 compliance).

Usage:
    python3 src/align_tables.py docs/*.md
"""

import sys


def align_table(lines):
    """Align all pipes in a markdown table."""
    rows = []
    for line in lines:
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        rows.append(cells)

    if len(rows) < 2:
        return lines

    num_cols = len(rows[0])

    # Find max width per column (skip separator row)
    widths = [0] * num_cols
    for i, row in enumerate(rows):
        if i == 1:
            continue
        for j, cell in enumerate(row):
            if j < num_cols:
                widths[j] = max(widths[j], len(cell))

    # Rebuild rows with aligned pipes
    result = []
    for i, row in enumerate(rows):
        if i == 1:
            parts = ["| " + "-" * widths[j] + " " for j in range(num_cols)]
        else:
            parts = [
                "| " + (row[j] if j < len(row) else "").ljust(widths[j]) + " "
                for j in range(num_cols)
            ]
        result.append("".join(parts) + "|")
    return result


def process_file(path):
    """Process a single markdown file."""
    with open(path) as f:
        lines = f.read().splitlines()

    result = []
    table_buf = []
    in_table = False

    for line in lines:
        is_table = line.strip().startswith("|") and "|" in line.strip()[1:]
        if is_table:
            table_buf.append(line)
            in_table = True
        else:
            if in_table:
                result.extend(align_table(table_buf))
                table_buf = []
                in_table = False
            result.append(line)

    if table_buf:
        result.extend(align_table(table_buf))

    with open(path, "w") as f:
        f.write("\n".join(result) + "\n")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file.md> [file2.md ...]")
        sys.exit(1)

    for path in sys.argv[1:]:
        process_file(path)
        print(f"Aligned: {path}")
