## 全局事件总线：跨系统解耦通信
extends Node

signal customer_served(perfect: bool, coins: int)
signal customer_left_angry()
signal day_ended(stats: Dictionary)
signal day_started(day: int)
