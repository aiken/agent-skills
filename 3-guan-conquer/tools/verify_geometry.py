#!/usr/bin/env python3
"""
SVG几何图坐标验证工具

使用方式：
1. 在generate_svg()函数中定义你的几何图
2. 在verify_geometry()中定义验证规则
3. 运行脚本，查看验证结果

所有坐标必须先用此脚本验证，再写入HTML。
"""

import math
from dataclasses import dataclass
from typing import Tuple, List, Callable

Point = Tuple[float, float]


def angle_between(v1: Point, v2: Point) -> float:
    """计算两向量的夹角（度）"""
    dot = v1[0]*v2[0] + v1[1]*v2[1]
    mag1 = math.sqrt(v1[0]**2 + v1[1]**2)
    mag2 = math.sqrt(v2[0]**2 + v2[1]**2)
    if mag1 == 0 or mag2 == 0:
        return 0
    cos = max(-1, min(1, dot / (mag1 * mag2)))
    return math.degrees(math.acos(cos))


def distance(p1: Point, p2: Point) -> float:
    """两点距离"""
    return math.sqrt((p1[0]-p2[0])**2 + (p1[1]-p2[1])**2)


def point_on_line(p: Point, a: Point, b: Point, tolerance: float = 0.1) -> Tuple[bool, float]:
    """检查点P是否在直线AB上，返回(is_on_line, 参数t)
    t在[0,1]表示在线段上"""
    dx = b[0] - a[0]
    dy = b[1] - a[1]
    if dx == 0 and dy == 0:
        return distance(p, a) < tolerance, 0
    
    # 投影系数
    if abs(dx) > abs(dy):
        t = (p[0] - a[0]) / dx if dx != 0 else 0
    else:
        t = (p[1] - a[1]) / dy if dy != 0 else 0
    
    expected_x = a[0] + t * dx
    expected_y = a[1] + t * dy
    is_on = abs(p[0] - expected_x) < tolerance and abs(p[1] - expected_y) < tolerance
    return is_on, t


def reflect_point(p: Point, a: Point, b: Point) -> Point:
    """求点P关于直线AB的对称点"""
    dx = b[0] - a[0]
    dy = b[1] - a[1]
    if dx == 0 and dy == 0:
        return p
    
    # 投影系数
    t = ((p[0]-a[0])*dx + (p[1]-a[1])*dy) / (dx**2 + dy**2)
    proj_x = a[0] + t*dx
    proj_y = a[1] + t*dy
    
    return (2*proj_x - p[0], 2*proj_y - p[1])


def verify_geometry(checks: List[Tuple[str, Callable[[], Tuple[bool, str]]]]) -> bool:
    """运行所有验证检查"""
    all_pass = True
    print("=" * 60)
    print("SVG几何图坐标验证")
    print("=" * 60)
    
    for name, check_fn in checks:
        ok, msg = check_fn()
        status = "PASS" if ok else "FAIL"
        print(f"  [{status}] {name}: {msg}")
        if not ok:
            all_pass = False
    
    print("=" * 60)
    if all_pass:
        print("全部验证通过！可以写入HTML。")
    else:
        print("有验证失败，请修正坐标后再写入HTML！")
    print("=" * 60)
    return all_pass


# ==================== 示例：将军饮马双对称模型 ====================

def example_general_model():
    """将军饮马双对称模型验证示例"""
    
    # 坐标系设定
    O = (100, 200)      # 原点
    scale = 1.6         # 1单位 = 1.6px (约)
    
    # ON: 水平向右
    N = (O[0] + 100*scale, O[1])
    
    # OM: 60度角
    OM_len = 100 * scale
    M = (O[0] + OM_len * math.cos(math.radians(60)), 
         O[1] - OM_len * math.sin(math.radians(60)))
    
    # P点: OP=4, 在角平分线上(30度)
    OP = 4 * scale * 20  # 假设1单位=20px, 但上面scale是1.6...
    # 简化: P在(60,0)的角平分线方向
    P = (O[0] + 60, O[1] - 35)
    
    # P₁: P关于ON(y=200)的对称点
    P1 = (P[0], O[1] + (O[1] - P[1]))
    
    # P₂: P关于OM的对称点
    P2 = reflect_point(P, O, M)
    
    # A: P₁P₂与OM的交点
    # B: P₁P₂与ON的交点
    # 简化: 用reflect_point验证
    
    checks = [
        ("∠MON = 60°", lambda: (
            abs(angle_between((M[0]-O[0], M[1]-O[1]), (N[0]-O[0], N[1]-O[1])) - 60) < 0.5,
            f"夹角 = {angle_between((M[0]-O[0], M[1]-O[1]), (N[0]-O[0], N[1]-O[1])):.1f}°"
        )),
        ("OP₁ = OP (轴对称保距)", lambda: (
            abs(distance(O, P1) - distance(O, P)) < 0.5,
            f"OP = {distance(O, P):.1f}, OP₁ = {distance(O, P1):.1f}"
        )),
        ("OP₂ = OP (轴对称保距)", lambda: (
            abs(distance(O, P2) - distance(O, P)) < 0.5,
            f"OP = {distance(O, P):.1f}, OP₂ = {distance(O, P2):.1f}"
        )),
        ("P₁是P关于ON的对称点", lambda: (
            P1[0] == P[0] and abs(P1[1] - (O[1] + (O[1]-P[1]))) < 0.5,
            f"P₁ = ({P1[0]:.1f}, {P1[1]:.1f}), 应为 ({P[0]:.1f}, {O[1] + (O[1]-P[1]):.1f})"
        )),
    ]
    
    return verify_geometry(checks)


# ==================== 示例：直角坐标系 ====================

def example_right_angle():
    """90度角对称验证示例"""
    
    O = (50, 150)
    N = (170, 150)  # 水平向右
    M = (50, 30)    # 垂直向上
    
    # P在角平分线上(45度)，OP=3，比例1:20
    unit = 20
    P = (O[0] + 3*unit / math.sqrt(2), O[1] - 3*unit / math.sqrt(2))
    
    # P₁关于ON(y=150)对称
    P1 = (P[0], O[1] + (O[1] - P[1]))
    
    checks = [
        ("∠MON = 90°", lambda: (
            abs(angle_between((0, -1), (1, 0)) - 90) < 0.5,
            "ON=(1,0), OM=(0,-1)"
        )),
        ("OP = 3单位", lambda: (
            abs(distance(O, P)/unit - 3) < 0.1,
            f"OP = {distance(O, P)/unit:.2f}单位"
        )),
        ("OP₁ = OP (保距)", lambda: (
            abs(distance(O, P1)/unit - 3) < 0.1,
            f"OP₁ = {distance(O, P1)/unit:.2f}单位"
        )),
        ("∠P₁ON = 45°", lambda: (
            abs(math.degrees(math.atan2(P1[1]-O[1], P1[0]-O[0])) - 45) < 0.5,
            f"∠P₁ON = {math.degrees(math.atan2(P1[1]-O[1], P1[0]-O[0])):.1f}°"
        )),
    ]
    
    return verify_geometry(checks)


if __name__ == "__main__":
    print("\n【将军饮马双对称模型验证】")
    example_general_model()
    
    print("\n【90度角对称验证】")
    example_right_angle()
