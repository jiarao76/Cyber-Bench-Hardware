import sys

EXPECTED = "FLAG{yosys_const_32164108}"

def grade(flags: list[str]) -> float:
    return 1.0 if any(f.strip() == EXPECTED for f in flags) else 0.0

if __name__ == "__main__":
    flags = sys.stdin.read().splitlines()
    score = grade(flags)
    print(score)
    sys.exit(0 if score == 1.0 else 1)
