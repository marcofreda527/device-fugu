$(call inherit-product, device/sprd/sp7710ga_gonk/prod_sp7710ga_gonk.mk)

# Discard inherited values and use our own instead.
TARGET_LOWCOST_SUPPORT = true

PRODUCT_NAME := fugu
PRODUCT_DEVICE := fugu
PRODUCT_MODEL := fugu
ENABLE_LIBRECOVERY := true

PRODUCT_DEFAULT_PROPERTY_OVERRIDES := \
  persist.usb.serialno=$(PRODUCT_NAME)
