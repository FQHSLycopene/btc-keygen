package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"github.com/btcsuite/btcd/btcec/v2"
	"github.com/btcsuite/btcd/btcutil"
	"github.com/btcsuite/btcd/chaincfg"
	"github.com/btcsuite/btcd/txscript"
)

// 定义地址类型常量
const (
	AddressTypeP2PKH  = "p2pkh"  // 传统地址（1开头）
	AddressTypeP2SH   = "p2sh"   // 脚本哈希地址（3开头）
	AddressTypeP2WPKH = "p2wpkh" // 隔离见证地址（bc1开头）
	AddressTypeP2TR   = "p2tr"   // Taproot地址（bc1p开头）
)

var (
	generateKey   = flag.Bool("generate", false, "生成新的比特币密钥对")
	importPrivKey = flag.String("import", "", "导入私钥（WIF格式）")
	addressType   = flag.String("type", AddressTypeP2PKH, "地址类型: p2pkh, p2sh, p2wpkh, p2tr")
	testnet       = flag.Bool("testnet", false, "使用测试网络")
)

func main() {
	flag.Parse()

	if *generateKey && *importPrivKey != "" {
		log.Fatal("不能同时指定 -generate 和 -import 参数")
	}

	if !*generateKey && *importPrivKey == "" {
		flag.Usage()
		os.Exit(1)
	}

	// 确定使用的网络参数
	params := &chaincfg.MainNetParams
	if *testnet {
		params = &chaincfg.TestNet3Params
	}

	// 生成新密钥对或导入现有私钥
	if *generateKey {
		generateKeyPair(*addressType, params)
	} else {
		importPrivateKey(*importPrivKey, *addressType, params)
	}
}

// 生成新的密钥对
func generateKeyPair(addressType string, params *chaincfg.Params) {
	// 生成私钥
	privateKey, err := btcec.NewPrivateKey()
	if err != nil {
		log.Fatalf("生成私钥失败: %v", err)
	}

	// 将私钥转换为WIF格式
	wif, err := btcutil.NewWIF(privateKey, params, true)
	if err != nil {
		log.Fatalf("转换WIF格式失败: %v", err)
	}

	// 从私钥获取公钥
	pubKey := privateKey.PubKey()
	pubKeyBytes := pubKey.SerializeCompressed()

	// 根据地址类型生成对应地址
	var address btcutil.Address
	var addrErr error

	switch addressType {
	case AddressTypeP2PKH:
		// 传统地址
		address, addrErr = btcutil.NewAddressPubKeyHash(btcutil.Hash160(pubKeyBytes), params)

	case AddressTypeP2SH:
		// P2SH-P2WPKH地址（将P2WPKH脚本包装在P2SH中）
		witnessProg := btcutil.Hash160(pubKeyBytes)
		redeemScript, _ := txscript.NewScriptBuilder().
			AddOp(txscript.OP_0).
			AddData(witnessProg).
			Script()
		address, addrErr = btcutil.NewAddressScriptHash(redeemScript, params)

	case AddressTypeP2WPKH:
		// 原生隔离见证地址
		witnessProg := btcutil.Hash160(pubKeyBytes)
		address, addrErr = btcutil.NewAddressWitnessPubKeyHash(witnessProg, params)

	case AddressTypeP2TR:
		// Taproot地址 (BIP341)
		// 使用X-only公钥（32字节）
		// 直接使用公钥的X坐标
		witnessProgram := pubKey.X().Bytes()
		address, addrErr = btcutil.NewAddressTaproot(witnessProgram, params)

	default:
		addrErr = fmt.Errorf("未知的地址类型: %s", addressType)
	}

	if addrErr != nil {
		log.Printf("警告: 无法生成 %s 类型的地址: %v", addressType, addrErr)
	}

	// 输出结果
	networkName := "主网"
	if params.Name != "mainnet" {
		networkName = "测试网"
	}

	fmt.Printf("生成了新的比特币密钥对（%s，%s）\n", addressType, networkName)
	fmt.Printf("私钥 (WIF格式): %s\n", wif.String())
	fmt.Printf("公钥 (压缩格式): %x\n", pubKeyBytes)

	if addrErr == nil {
		fmt.Printf("地址: %s\n", address.EncodeAddress())
	} else {
		fmt.Printf("地址: 不支持生成此类型地址\n")
	}
}

// 导入私钥并计算公钥
func importPrivateKey(wifStr string, addressType string, params *chaincfg.Params) {
	// 解析WIF格式私钥
	wif, err := btcutil.DecodeWIF(wifStr)
	if err != nil {
		log.Fatalf("无效的WIF格式私钥: %v", err)
	}

	// 检查网络兼容性
	if !wif.IsForNet(params) {
		log.Fatalf("私钥网络类型不匹配")
	}

	// 获取公钥
	pubKey := wif.PrivKey.PubKey()
	pubKeyBytes := pubKey.SerializeCompressed()

	// 根据地址类型生成对应地址
	var address btcutil.Address
	var addrErr error

	switch addressType {
	case AddressTypeP2PKH:
		// 传统地址
		address, addrErr = btcutil.NewAddressPubKeyHash(btcutil.Hash160(pubKeyBytes), params)

	case AddressTypeP2SH:
		// P2SH-P2WPKH地址（将P2WPKH脚本包装在P2SH中）
		witnessProg := btcutil.Hash160(pubKeyBytes)
		redeemScript, _ := txscript.NewScriptBuilder().
			AddOp(txscript.OP_0).
			AddData(witnessProg).
			Script()
		address, addrErr = btcutil.NewAddressScriptHash(redeemScript, params)

	case AddressTypeP2WPKH:
		// 原生隔离见证地址
		witnessProg := btcutil.Hash160(pubKeyBytes)
		address, addrErr = btcutil.NewAddressWitnessPubKeyHash(witnessProg, params)

	case AddressTypeP2TR:
		// Taproot地址 (BIP341)
		// 使用X-only公钥（32字节）
		// 直接使用公钥的X坐标
		witnessProgram := pubKey.X().Bytes()
		address, addrErr = btcutil.NewAddressTaproot(witnessProgram, params)

	default:
		addrErr = fmt.Errorf("未知的地址类型: %s", addressType)
	}

	if addrErr != nil {
		log.Printf("警告: 无法生成 %s 类型的地址: %v", addressType, addrErr)
	}

	// 输出结果
	networkName := "主网"
	if params.Name != "mainnet" {
		networkName = "测试网"
	}

	fmt.Printf("从私钥导入的比特币公钥（%s，%s）\n", addressType, networkName)
	fmt.Printf("公钥 (压缩格式): %x\n", pubKeyBytes)

	if addrErr == nil {
		fmt.Printf("地址: %s\n", address.EncodeAddress())
	} else {
		fmt.Printf("地址: 不支持生成此类型地址\n")
	}
}
