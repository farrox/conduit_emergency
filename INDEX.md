# Conduit CLI Emergency Package - Index

**Quick navigation for all documentation and resources**

## 🚀 Start Here

1. **New to this?** → [QUICK_START.md](QUICK_START.md)
2. **Need to develop?** → [LLM_DEV_GUIDE.md](LLM_DEV_GUIDE.md)
3. **Want overview?** → [README_EMERGENCY.md](README_EMERGENCY.md)

## 📚 Documentation Files

| File | Purpose | Audience |
|------|---------|----------|
| [README_EMERGENCY.md](README_EMERGENCY.md) | Overview and quick reference | Everyone |
| [QUICK_START.md](QUICK_START.md) | Simple step-by-step guide | Non-technical users |
| [LLM_DEV_GUIDE.md](LLM_DEV_GUIDE.md) | Comprehensive dev guide | Developers / LLMs |
| [README.md](README.md) | Original CLI documentation | Users |
| [SETUP-GUIDE.md](SETUP-GUIDE.md) | Detailed setup walkthrough | First-time setup |
| [INSTALL-GO.md](INSTALL-GO.md) | Go installation guide | Setup |

## ⚡ Quick Commands

```bash
# Test everything
./TEST_EMERGENCY_SETUP.sh

# Run (if binary exists)
./dist/conduit start --psiphon-config ./psiphon_config.json

# Build (if needed)
export PATH="/usr/local/opt/go@1.24/bin:$PATH"
make setup && make build
```

## 📁 Key Files

- `dist/conduit` - Built binary (ready to run)
- `psiphon_config.json` - Real Psiphon config (REQUIRED)
- `main.go` - Entry point
- `Makefile` - Build system
- `go.mod` - Go dependencies

## ✅ Status

Run `./TEST_EMERGENCY_SETUP.sh` to verify everything works.

---

**Last Updated**: 2026-01-25
