# open_digital_lib

- [English](#english)
- [中文](#中文)

# English

This repository contains foundational building blocks for digital circuit design.

## module list

#### clock & reset
- **ODL_clock_switch**：glitch-free clock switching circuit
- **ODL_rst_sync**：reset synchronizer

#### arbiter
- **ODL_fpa**：fixed/simple priority arbiter
- **ODL_wrr**：weighted round robin arbiter
- **ODL_wrr_fair**：weighted round robin arbiter - fair distribution
  
#### encryption
- **ODL_aes_128**：aes_128 core
  
#### encoding conversion
- **ODL_bin_to_gray**：binary to gray code
- **ODL_bin_to_onehot**：binary to one-hot code
- **ODL_gray_to_bin**：gray code to binary
- **ODL_onehot_to_bin**：one-hot code to binary

#### multiplier
- **ODL_mult_array_55**：5×5 array multiplier
- **ODL_mult_array**：parameterized N×N array multiplier
- **ODL_mult_booth_33**：33-bit signed multiplier using Modified Booth encoding and Wallace tree compression
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

#### 时钟复位
- **ODL_clock_switch**：无毛刺时钟切换电路
- **ODL_rst_sync**： 复位同步器
  
#### 仲裁器
- **ODL_fpa**：固定优先级仲裁器
- **ODL_wrr**：加权轮询仲裁器
- **ODL_wrr_fair**：近似均匀分布的加权轮询仲裁器
  
#### 加解密
- **ODL_aes_128**：aes_128算法核

#### 编码转换
- **ODL_bin_to_gray**：二进制转格雷码
- **ODL_bin_to_onehot**：二进制转独热码
- **ODL_gray_to_bin**：格雷码转二进制
- **ODL_onehot_to_bin**：独热码转二进制

#### 乘法器
- **ODL_mult_array_55**：5×5 阵列乘法器
- **ODL_mult_array**：参数化 N×N 阵列乘法器
- **ODL_mult_booth_33**：33-bit 有符号乘法器，采用改进 Booth 编码和 Wallace 树压缩
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

