import math
from typing import Iterable


def mean(values: Iterable[float]) -> float:
    vals = [float(v) for v in values]
    if not vals:
        return 0.0
    return sum(vals) / len(vals)


def percentile(values: Iterable[float], p: float) -> float:
    vals = sorted(float(v) for v in values)
    if not vals:
        return 0.0
    if p <= 0:
        return vals[0]
    if p >= 100:
        return vals[-1]
    rank = math.ceil((p / 100.0) * len(vals))
    idx = max(1, rank) - 1
    return vals[idx]


def confidence_interval_95(values: Iterable[float]) -> tuple[float, float]:
    vals = [float(v) for v in values]
    if not vals:
        return (0.0, 0.0)
    m = mean(vals)
    if len(vals) < 2:
        return (m, m)

    variance = sum((v - m) ** 2 for v in vals) / (len(vals) - 1)
    std = math.sqrt(max(0.0, variance))
    margin = 1.96 * std / math.sqrt(len(vals))
    return (m - margin, m + margin)


def proportion_confidence_interval_95(successes: int, trials: int) -> tuple[float, float]:
    if trials <= 0:
        return (0.0, 0.0)
    p = successes / trials
    margin = 1.96 * math.sqrt(max(0.0, p * (1.0 - p) / trials))
    return (max(0.0, p - margin), min(1.0, p + margin))


def summarize_series(values: Iterable[float]) -> dict:
    vals = [float(v) for v in values]
    if not vals:
        return {
            "count": 0,
            "min": 0.0,
            "max": 0.0,
            "mean": 0.0,
            "p50": 0.0,
            "p95": 0.0,
            "ci95_lower": 0.0,
            "ci95_upper": 0.0,
        }

    ci_low, ci_high = confidence_interval_95(vals)
    return {
        "count": len(vals),
        "min": min(vals),
        "max": max(vals),
        "mean": mean(vals),
        "p50": percentile(vals, 50),
        "p95": percentile(vals, 95),
        "ci95_lower": ci_low,
        "ci95_upper": ci_high,
    }
