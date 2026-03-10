# open_digital_lib

- [English](#english)
- [中文](#中文)

# English

This repository contains foundational building blocks for digital circuit design.

## module

- **ODL_clock_switch**：glitch-free clock switching circuit
- **ODL_fpa**：fixed/simple priority arbiter
- **ODL_wrr**：weighted round robin arbiter
- **ODL_wrr_fair**：weighted round robin arbiter - fair distribution

## simulation

Requirements：

- verilator
- cocotb
- gtkwave

Run a testcase:
```
cd vrf
make clean
make TC=wrr_fair
```

Check the waveform:
```
make wave TC=wrr_fair
```

# 中文

本仓库包含用于构建数字芯片的基本模块，[详细介绍](https://mp.weixin.qq.com/s/nQ6PGeMVyil1QYWKGnyz-A)。

## 模块列表

design 目录下包含设计代码：

- **ODL_clock_switch**：无毛刺时钟切换电路
- **ODL_fpa**：固定优先级仲裁器
- **ODL_wrr**：加权轮询仲裁器
- **ODL_wrr_fair**：近似均匀分布的加权轮询仲裁器

## 仿真

vrf 目录下包含测试用例，需要安装以下开源工具：

- verilator
- cocotb
- gtkwave

运行测试用例：
```
cd vrf
make clean
make TC=wrr_fair
```

查看波形：
```
make wave TC=wrr_fair
```

