#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


SUPEE-8788 | EE_1.12.0.1 | v1 | 5551bbc7c775b3a5fc150fb621c75e14713dba4a | Mon Sep 26 11:27:22 2016 +0300 | 01faed3ae7..5551bbc7c7

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Category.php app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Category.php
index 44cfc17..6554a66 100644
--- app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Category.php
+++ app/code/core/Enterprise/CatalogEvent/Block/Adminhtml/Event/Edit/Category.php
@@ -105,7 +105,7 @@ class Enterprise_CatalogEvent_Block_Adminhtml_Event_Edit_Category extends Mage_A
                                     $node->getId(),
                                     $this->helper('enterprise_catalogevent/adminhtml_event')->getInEventCategoryIds()
                                 )),
-            'name'           => $node->getName(),
+            'name'           => $this->escapeHtml($node->getName()),
             'level'          => (int)$node->getLevel(),
             'product_count'  => (int)$node->getProductCount(),
         );
diff --git app/code/core/Enterprise/Checkout/controllers/CartController.php app/code/core/Enterprise/Checkout/controllers/CartController.php
index 8e95ee3..28eae79 100644
--- app/code/core/Enterprise/Checkout/controllers/CartController.php
+++ app/code/core/Enterprise/Checkout/controllers/CartController.php
@@ -91,6 +91,9 @@ class Enterprise_Checkout_CartController extends Mage_Core_Controller_Front_Acti
      */
     public function advancedAddAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
         // check empty data
         /** @var $helper Enterprise_Checkout_Helper_Data */
         $helper = Mage::helper('enterprise_checkout');
@@ -131,6 +134,9 @@ class Enterprise_Checkout_CartController extends Mage_Core_Controller_Front_Acti
      */
     public function addFailedItemsAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
         $failedItemsCart = $this->_getFailedItemsCart()->removeAllAffectedItems();
         $failedItems = $this->getRequest()->getParam('failed', array());
         foreach ($failedItems as $data) {
@@ -232,7 +238,7 @@ class Enterprise_Checkout_CartController extends Mage_Core_Controller_Front_Acti
             $this->_getFailedItemsCart()->removeAffectedItem($this->getRequest()->getParam('sku'));
 
             if (!$this->_getSession()->getNoCartRedirect(true)) {
-                if (!$cart->getQuote()->getHasError()){
+                if (!$cart->getQuote()->getHasError()) {
                     $productName = Mage::helper('core')->escapeHtml($product->getName());
                     $message = $this->__('%s was added to your shopping cart.', $productName);
                     $this->_getSession()->addSuccess($message);
diff --git app/code/core/Enterprise/GiftRegistry/controllers/ViewController.php app/code/core/Enterprise/GiftRegistry/controllers/ViewController.php
index 9878c3e..cbf1304 100644
--- app/code/core/Enterprise/GiftRegistry/controllers/ViewController.php
+++ app/code/core/Enterprise/GiftRegistry/controllers/ViewController.php
@@ -75,7 +75,8 @@ class Enterprise_GiftRegistry_ViewController extends Mage_Core_Controller_Front_
     public function addToCartAction()
     {
         $items = $this->getRequest()->getParam('items');
-        if (!$items) {
+
+        if (!$items || !$this->_validateFormKey()) {
             $this->_redirect('*/*', array('_current' => true));
             return;
         }
diff --git app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php
index 3185cef..30e59d9 100644
--- app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php
+++ app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php
@@ -136,12 +136,24 @@ class Enterprise_ImportExport_Model_Scheduled_Operation extends Mage_Core_Model_
     {
         $fileInfo = $this->getFileInfo();
         if (trim($fileInfo)) {
-            $this->setFileInfo(unserialize($fileInfo));
+            try {
+                $fileInfo = Mage::helper('core/unserializeArray')
+                    ->unserialize($fileInfo);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $this->setFileInfo($fileInfo);
         }
 
         $attrsInfo = $this->getEntityAttributes();
         if (trim($attrsInfo)) {
-            $this->setEntityAttributes(unserialize($attrsInfo));
+            try {
+                $attrsInfo = Mage::helper('core/unserializeArray')
+                    ->unserialize($attrsInfo);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $this->setEntityAttributes($attrsInfo);
         }
 
         return parent::_afterLoad();
diff --git app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php
index 05aafa7..14417a2 100644
--- app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php
+++ app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php
@@ -76,7 +76,8 @@ class Enterprise_Invitation_Block_Adminhtml_Invitation_Grid extends Mage_Adminht
         $this->addColumn('email', array(
             'header' => Mage::helper('enterprise_invitation')->__('Email'),
             'index' => 'invitation_email',
-            'type'  => 'text'
+            'type'  => 'text',
+            'escape' => true
         ));
 
         $renderer = (Mage::getSingleton('admin/session')->isAllowed('customer/manage'))
diff --git app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/View.php app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/View.php
index c065db9..716af4a 100644
--- app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/View.php
+++ app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/View.php
@@ -40,7 +40,7 @@ class Enterprise_Invitation_Block_Adminhtml_Invitation_View extends Mage_Adminht
     protected function _prepareLayout()
     {
         $invitation = $this->getInvitation();
-        $this->_headerText = Mage::helper('enterprise_invitation')->__('View Invitation for %s (ID: %s)', $invitation->getEmail(), $invitation->getId());
+        $this->_headerText = Mage::helper('enterprise_invitation')->__('View Invitation for %s (ID: %s)', Mage::helper('core')->escapeHtml($invitation->getEmail()), $invitation->getId());
         $this->_addButton('back', array(
             'label' => Mage::helper('enterprise_invitation')->__('Back'),
             'onclick' => "setLocation('{$this->getUrl('*/*/')}')",
diff --git app/code/core/Enterprise/Invitation/controllers/IndexController.php app/code/core/Enterprise/Invitation/controllers/IndexController.php
index 30174c9..895ea09 100644
--- app/code/core/Enterprise/Invitation/controllers/IndexController.php
+++ app/code/core/Enterprise/Invitation/controllers/IndexController.php
@@ -80,7 +80,9 @@ class Enterprise_Invitation_IndexController extends Mage_Core_Controller_Front_A
                         'message'  => (isset($data['message']) ? $data['message'] : ''),
                     ))->save();
                     if ($invitation->sendInvitationEmail()) {
-                        Mage::getSingleton('customer/session')->addSuccess(Mage::helper('enterprise_invitation')->__('Invitation for %s has been sent.', $email));
+                        Mage::getSingleton('customer/session')->addSuccess(
+                            Mage::helper('enterprise_invitation')->__('Invitation for %s has been sent.', Mage::helper('core')->escapeHtml($email))
+                        );
                         $sent++;
                     }
                     else {
@@ -97,7 +99,9 @@ class Enterprise_Invitation_IndexController extends Mage_Core_Controller_Front_A
                     }
                 }
                 catch (Exception $e) {
-                    Mage::getSingleton('customer/session')->addError(Mage::helper('enterprise_invitation')->__('Failed to send email to %s.', $email));
+                    Mage::getSingleton('customer/session')->addError(
+                        Mage::helper('enterprise_invitation')->__('Failed to send email to %s.', Mage::helper('core')->escapeHtml($email))
+                    );
                 }
             }
             if ($customerExists) {
diff --git app/code/core/Enterprise/PageCache/Helper/Data.php app/code/core/Enterprise/PageCache/Helper/Data.php
index d6036d5..6da350e 100644
--- app/code/core/Enterprise/PageCache/Helper/Data.php
+++ app/code/core/Enterprise/PageCache/Helper/Data.php
@@ -23,7 +23,66 @@
  * @copyright   Copyright (c) 2012 Magento Inc. (http://www.magentocommerce.com)
  * @license     http://www.magentocommerce.com/license/enterprise-edition
  */
-
+/**
+ * PageCache Data helper
+ *
+ * @category    Enterprise
+ * @package     Enterprise_PageCache
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
 class Enterprise_PageCache_Helper_Data extends Mage_Core_Helper_Abstract
 {
+    /**
+     * Character sets
+     */
+    const CHARS_LOWERS                          = 'abcdefghijklmnopqrstuvwxyz';
+    const CHARS_UPPERS                          = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
+    const CHARS_DIGITS                          = '0123456789';
+
+    /**
+     * Get random generated string
+     *
+     * @param int $len
+     * @param string|null $chars
+     * @return string
+     */
+    public static function getRandomString($len, $chars = null)
+    {
+        if (is_null($chars)) {
+            $chars = self::CHARS_LOWERS . self::CHARS_UPPERS . self::CHARS_DIGITS;
+        }
+        mt_srand(10000000*(double)microtime());
+        for ($i = 0, $str = '', $lc = strlen($chars)-1; $i < $len; $i++) {
+            $str .= $chars[mt_rand(0, $lc)];
+        }
+        return $str;
+    }
+
+    /**
+     * Wrap string with placeholder wrapper
+     *
+     * @param string $string
+     * @return string
+     */
+    public static function wrapPlaceholderString($string)
+    {
+        return '{{' . chr(1) . chr(2) . chr(3) . $string . chr(3) . chr(2) . chr(1) . '}}';
+    }
+
+    /**
+     * Prepare content for saving
+     *
+     * @param string $content
+     */
+    public static function prepareContentPlaceholders(&$content)
+    {
+        /**
+         * Replace all occurrences of session_id with unique marker
+         */
+        Enterprise_PageCache_Helper_Url::replaceSid($content);
+        /**
+         * Replace all occurrences of form_key with unique marker
+         */
+        Enterprise_PageCache_Helper_Form_Key::replaceFormKey($content);
+    }
 }
diff --git app/code/core/Enterprise/PageCache/Helper/Form/Key.php app/code/core/Enterprise/PageCache/Helper/Form/Key.php
new file mode 100644
index 0000000..58983d6
--- /dev/null
+++ app/code/core/Enterprise/PageCache/Helper/Form/Key.php
@@ -0,0 +1,79 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition License
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magentocommerce.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magentocommerce.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magentocommerce.com for more information.
+ *
+ * @category    Enterprise
+ * @package     Enterprise_PageCache
+ * @copyright   Copyright (c) 2012 Magento Inc. (http://www.magentocommerce.com)
+ * @license     http://www.magentocommerce.com/license/enterprise-edition
+ */
+/**
+ * PageCache Form Key helper
+ *
+ * @category    Enterprise
+ * @package     Enterprise_PageCache
+ * @author      Magento Core Team <core@magentocommerce.com>
+ */
+class Enterprise_PageCache_Helper_Form_Key extends Mage_Core_Helper_Abstract
+{
+    /**
+     * Retrieve unique marker value
+     *
+     * @return string
+     */
+    protected static function _getFormKeyMarker()
+    {
+        return Enterprise_PageCache_Helper_Data::wrapPlaceholderString('_FORM_KEY_MARKER_');
+    }
+
+    /**
+     * Replace form key with placeholder string
+     *
+     * @param string $content
+     * @return bool
+     */
+    public static function replaceFormKey(&$content)
+    {
+        if (!$content) {
+            return $content;
+        }
+        /** @var $session Mage_Core_Model_Session */
+        $session = Mage::getSingleton('core/session');
+        $replacementCount = 0;
+        $content = str_replace($session->getFormKey(), self::_getFormKeyMarker(), $content, $replacementCount);
+        return ($replacementCount > 0);
+    }
+
+    /**
+     * Restore user form key in form key placeholders
+     *
+     * @param string $content
+     * @param string $formKey
+     * @return bool
+     */
+    public static function restoreFormKey(&$content, $formKey)
+    {
+        if (!$content) {
+            return false;
+        }
+        $replacementCount = 0;
+        $content = str_replace(self::_getFormKeyMarker(), $formKey, $content, $replacementCount);
+        return ($replacementCount > 0);
+    }
+}
diff --git app/code/core/Enterprise/PageCache/Helper/Url.php app/code/core/Enterprise/PageCache/Helper/Url.php
index 5730b00..0a833bf 100644
--- app/code/core/Enterprise/PageCache/Helper/Url.php
+++ app/code/core/Enterprise/PageCache/Helper/Url.php
@@ -26,6 +26,10 @@
 
 /**
  * Url processing helper
+ *
+ * @category    Enterprise
+ * @package     Enterprise_PageCache
+ * @author      Magento Core Team <core@magentocommerce.com>
  */
 class Enterprise_PageCache_Helper_Url
 {
@@ -36,7 +40,7 @@ class Enterprise_PageCache_Helper_Url
      */
     protected static function _getSidMarker()
     {
-        return '{{' . chr(1) . chr(2) . chr(3) . '_SID_MARKER_' . chr(3) . chr(2) . chr(1) . '}}';
+        return Enterprise_PageCache_Helper_Data::wrapPlaceholderString('_SID_MARKER_');
     }
 
     /**
@@ -63,7 +67,8 @@ class Enterprise_PageCache_Helper_Url
     /**
      * Restore session_id from marker value
      *
-     * @param  string $content
+     * @param string $content
+     * @param string $sidValue
      * @return bool
      */
     public static function restoreSid(&$content, $sidValue)
diff --git app/code/core/Enterprise/PageCache/Model/Container/Abstract.php app/code/core/Enterprise/PageCache/Model/Container/Abstract.php
index 70866b9..022a160 100644
--- app/code/core/Enterprise/PageCache/Model/Container/Abstract.php
+++ app/code/core/Enterprise/PageCache/Model/Container/Abstract.php
@@ -185,7 +185,7 @@ abstract class Enterprise_PageCache_Model_Container_Abstract
          * Replace all occurrences of session_id with unique marker
          */
         Enterprise_PageCache_Helper_Url::replaceSid($data);
-
+        Enterprise_PageCache_Helper_Data::prepareContentPlaceholders($data);
         Enterprise_PageCache_Model_Cache::getCacheInstance()->save($data, $id, $tags, $lifetime);
         return $this;
     }
diff --git app/code/core/Enterprise/PageCache/Model/Container/Advanced/Abstract.php app/code/core/Enterprise/PageCache/Model/Container/Advanced/Abstract.php
index 23614c4..4b46eb4 100644
--- app/code/core/Enterprise/PageCache/Model/Container/Advanced/Abstract.php
+++ app/code/core/Enterprise/PageCache/Model/Container/Advanced/Abstract.php
@@ -82,10 +82,7 @@ abstract class Enterprise_PageCache_Model_Container_Advanced_Abstract
                 $this->_placeholder->getAttribute('cache_lifetime') : false;
         }
 
-        /**
-         * Replace all occurrences of session_id with unique marker
-         */
-        Enterprise_PageCache_Helper_Url::replaceSid($data);
+        Enterprise_PageCache_Helper_Data::prepareContentPlaceholders($data);
 
         $result = array();
 
diff --git app/code/core/Enterprise/PageCache/Model/Cookie.php app/code/core/Enterprise/PageCache/Model/Cookie.php
index f263388..41b875b 100644
--- app/code/core/Enterprise/PageCache/Model/Cookie.php
+++ app/code/core/Enterprise/PageCache/Model/Cookie.php
@@ -49,6 +49,8 @@ class Enterprise_PageCache_Model_Cookie extends Mage_Core_Model_Cookie
 
     const COOKIE_CUSTOMER_LOGGED_IN = 'CUSTOMER_AUTH';
 
+    const COOKIE_FORM_KEY           = 'CACHED_FRONT_FORM_KEY';
+
     /**
      * Subprocessors cookie names
      */
@@ -210,4 +212,24 @@ class Enterprise_PageCache_Model_Cookie extends Mage_Core_Model_Cookie
     {
         setcookie(self::COOKIE_CATEGORY_ID, $id, 0, '/');
     }
+
+    /**
+     * Set cookie with form key for cached front
+     *
+     * @param string $formKey
+     */
+    public static function setFormKeyCookieValue($formKey)
+    {
+        setcookie(self::COOKIE_FORM_KEY, $formKey, 0, '/');
+    }
+
+    /**
+     * Get form key cookie value
+     *
+     * @return string|bool
+     */
+    public static function getFormKeyCookieValue()
+    {
+        return (isset($_COOKIE[self::COOKIE_FORM_KEY])) ? $_COOKIE[self::COOKIE_FORM_KEY] : false;
+    }
 }
diff --git app/code/core/Enterprise/PageCache/Model/Observer.php app/code/core/Enterprise/PageCache/Model/Observer.php
index 9e03664..f0555be 100755
--- app/code/core/Enterprise/PageCache/Model/Observer.php
+++ app/code/core/Enterprise/PageCache/Model/Observer.php
@@ -678,4 +678,23 @@ class Enterprise_PageCache_Model_Observer
         $segmentsIdsString= implode(',', $segmentIds);
         $this->_getCookie()->set(Enterprise_PageCache_Model_Cookie::CUSTOMER_SEGMENT_IDS, $segmentsIdsString);
     }
+
+    /**
+     * Register form key in session from cookie value
+     *
+     * @param Varien_Event_Observer $observer
+     */
+    public function registerCachedFormKey(Varien_Event_Observer $observer)
+    {
+        if (!$this->isCacheEnabled()) {
+            return;
+        }
+
+        /** @var $session Mage_Core_Model_Session  */
+        $session = Mage::getSingleton('core/session');
+        $cachedFrontFormKey = Enterprise_PageCache_Model_Cookie::getFormKeyCookieValue();
+        if ($cachedFrontFormKey) {
+            $session->setData('_form_key', $cachedFrontFormKey);
+        }
+    }
 }
diff --git app/code/core/Enterprise/PageCache/Model/Processor.php app/code/core/Enterprise/PageCache/Model/Processor.php
index c7c3ac8..f9e63d0 100644
--- app/code/core/Enterprise/PageCache/Model/Processor.php
+++ app/code/core/Enterprise/PageCache/Model/Processor.php
@@ -388,6 +388,15 @@ class Enterprise_PageCache_Model_Processor
             $isProcessed = false;
         }
 
+        if (isset($_COOKIE[Enterprise_PageCache_Model_Cookie::COOKIE_FORM_KEY])) {
+            $formKey = $_COOKIE[Enterprise_PageCache_Model_Cookie::COOKIE_FORM_KEY];
+        } else {
+            $formKey = Enterprise_PageCache_Helper_Data::getRandomString(16);
+            Enterprise_PageCache_Model_Cookie::setFormKeyCookieValue($formKey);
+        }
+
+        Enterprise_PageCache_Helper_Form_Key::restoreFormKey($content, $formKey);
+
         /**
          * restore session_id in content whether content is completely processed or not
          */
@@ -507,6 +516,7 @@ class Enterprise_PageCache_Model_Processor
                  * Replace all occurrences of session_id with unique marker
                  */
                 Enterprise_PageCache_Helper_Url::replaceSid($content);
+                Enterprise_PageCache_Helper_Form_Key::replaceFormKey($content);
 
                 if (function_exists('gzcompress')) {
                     $content = gzcompress($content);
@@ -685,7 +695,13 @@ class Enterprise_PageCache_Model_Processor
          * Define request URI
          */
         if ($uri) {
-            if (isset($_SERVER['REQUEST_URI'])) {
+            if (isset($_SERVER['HTTP_X_ORIGINAL_URL'])) {
+                // IIS with Microsoft Rewrite Module
+                $uri.= $_SERVER['HTTP_X_ORIGINAL_URL'];
+            } elseif (isset($_SERVER['HTTP_X_REWRITE_URL'])) {
+                // IIS with ISAPI_Rewrite
+                $uri.= $_SERVER['HTTP_X_REWRITE_URL'];
+            } elseif (isset($_SERVER['REQUEST_URI'])) {
                 $uri.= $_SERVER['REQUEST_URI'];
             } elseif (!empty($_SERVER['IIS_WasUrlRewritten']) && !empty($_SERVER['UNENCODED_URL'])) {
                 $uri.= $_SERVER['UNENCODED_URL'];
diff --git app/code/core/Enterprise/PageCache/etc/config.xml app/code/core/Enterprise/PageCache/etc/config.xml
index 3920644..3ac4eb5 100644
--- app/code/core/Enterprise/PageCache/etc/config.xml
+++ app/code/core/Enterprise/PageCache/etc/config.xml
@@ -245,6 +245,12 @@
                         <method>processPreDispatch</method>
                     </enterprise_pagecache>
                 </observers>
+                <observers>
+                    <enterprise_pagecache>
+                        <class>enterprise_pagecache/observer</class>
+                        <method>registerCachedFormKey</method>
+                    </enterprise_pagecache>
+                </observers>
             </controller_action_predispatch>
             <controller_action_postdispatch_catalog_product_view>
                 <observers>
diff --git app/code/core/Enterprise/Pbridge/Model/Pbridge/Api/Abstract.php app/code/core/Enterprise/Pbridge/Model/Pbridge/Api/Abstract.php
index 9270163..12c2587 100644
--- app/code/core/Enterprise/Pbridge/Model/Pbridge/Api/Abstract.php
+++ app/code/core/Enterprise/Pbridge/Model/Pbridge/Api/Abstract.php
@@ -55,6 +55,13 @@ class Enterprise_Pbridge_Model_Pbridge_Api_Abstract extends Varien_Object
         try {
             $http = new Varien_Http_Adapter_Curl();
             $config = array('timeout' => 60);
+            if (Mage::getStoreConfigFlag('payment/pbridge/verifyssl')) {
+                $config['verifypeer'] = true;
+                $config['verifyhost'] = 2;
+            } else {
+                $config['verifypeer'] = false;
+                $config['verifyhost'] = 0;
+            }
             $http->setConfig($config);
             $http->write(
                 Zend_Http_Client::POST,
diff --git app/code/core/Enterprise/Pbridge/etc/config.xml app/code/core/Enterprise/Pbridge/etc/config.xml
index 8a372d8..6997fa8 100644
--- app/code/core/Enterprise/Pbridge/etc/config.xml
+++ app/code/core/Enterprise/Pbridge/etc/config.xml
@@ -132,6 +132,7 @@
                 <model>enterprise_pbridge/payment_method_pbridge</model>
                 <title>Payment Bridge</title>
                 <debug>0</debug>
+                <verifyssl>0</verifyssl>
             </pbridge>
             <pbridge_paypal_direct>
                 <model>enterprise_pbridge/payment_method_paypal</model>
diff --git app/code/core/Enterprise/Pbridge/etc/system.xml app/code/core/Enterprise/Pbridge/etc/system.xml
index 2f9c701..e787d11 100644
--- app/code/core/Enterprise/Pbridge/etc/system.xml
+++ app/code/core/Enterprise/Pbridge/etc/system.xml
@@ -70,6 +70,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
                         </gatewayurl>
+                        <verifyssl translate="label" module="enterprise_pbridge">
+                            <label>Verify SSL Connection</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>50</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </verifyssl>
                         <transferkey translate="label" module="enterprise_pbridge">
                             <label>Data Transfer Key</label>
                             <frontend_type>text</frontend_type>
diff --git app/code/core/Enterprise/Pci/Model/Encryption.php app/code/core/Enterprise/Pci/Model/Encryption.php
index b349ec2..cd84d00 100644
--- app/code/core/Enterprise/Pci/Model/Encryption.php
+++ app/code/core/Enterprise/Pci/Model/Encryption.php
@@ -116,10 +116,10 @@ class Enterprise_Pci_Model_Encryption extends Mage_Core_Model_Encryption
         // look for salt
         $hashArr = explode(':', $hash, 2);
         if (1 === count($hashArr)) {
-            return $this->hash($password, $version) === $hash;
+            return hash_equals($this->hash($password, $version), $hash);
         }
         list($hash, $salt) = $hashArr;
-        return $this->hash($salt . $password, $version) === $hash;
+        return hash_equals($this->hash($salt . $password, $version), $hash);
     }
 
     /**
diff --git app/code/core/Enterprise/Wishlist/controllers/SearchController.php app/code/core/Enterprise/Wishlist/controllers/SearchController.php
index e8f4f9f..14491ea 100644
--- app/code/core/Enterprise/Wishlist/controllers/SearchController.php
+++ app/code/core/Enterprise/Wishlist/controllers/SearchController.php
@@ -179,6 +179,9 @@ class Enterprise_Wishlist_SearchController extends Mage_Core_Controller_Front_Ac
      */
     public function addtocartAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
         $messages   = array();
         $addedItems = array();
         $notSalable = array();
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
index f5a71f6..c44746c 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
@@ -34,6 +34,12 @@
  */
 class Mage_Adminhtml_Block_Catalog_Product_Helper_Form_Gallery_Content extends Mage_Adminhtml_Block_Widget
 {
+    /**
+     * Type of uploader block
+     *
+     * @var string
+     */
+    protected $_uploaderType = 'uploader/multiple';
 
     public function __construct()
     {
@@ -44,17 +50,17 @@ class Mage_Adminhtml_Block_Catalog_Product_Helper_Form_Gallery_Content extends M
     protected function _prepareLayout()
     {
         $this->setChild('uploader',
-            $this->getLayout()->createBlock('adminhtml/media_uploader')
+            $this->getLayout()->createBlock($this->_uploaderType)
         );
 
-        $this->getUploader()->getConfig()
-            ->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/catalog_product_gallery/upload'))
-            ->setFileField('image')
-            ->setFilters(array(
-                'images' => array(
-                    'label' => Mage::helper('adminhtml')->__('Images (.gif, .jpg, .png)'),
-                    'files' => array('*.gif', '*.jpg','*.jpeg', '*.png')
-                )
+        $this->getUploader()->getUploaderConfig()
+            ->setFileParameterName('image')
+            ->setTarget(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/catalog_product_gallery/upload'));
+
+        $browseConfig = $this->getUploader()->getButtonConfig();
+        $browseConfig
+            ->setAttributes(array(
+                'accept' => $browseConfig->getMimeTypesByExtensions('gif, png, jpeg, jpg')
             ));
 
         Mage::dispatchEvent('catalog_product_gallery_prepare_layout', array('block' => $this));
@@ -65,7 +71,7 @@ class Mage_Adminhtml_Block_Catalog_Product_Helper_Form_Gallery_Content extends M
     /**
      * Retrive uploader block
      *
-     * @return Mage_Adminhtml_Block_Media_Uploader
+     * @return Mage_Uploader_Block_Multiple
      */
     public function getUploader()
     {
diff --git app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
index 4e32e97..adbb8d7 100644
--- app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
+++ app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
@@ -31,29 +31,24 @@
  * @package    Mage_Adminhtml
  * @author     Magento Core Team <core@magentocommerce.com>
 */
-class Mage_Adminhtml_Block_Cms_Wysiwyg_Images_Content_Uploader extends Mage_Adminhtml_Block_Media_Uploader
+class Mage_Adminhtml_Block_Cms_Wysiwyg_Images_Content_Uploader extends Mage_Uploader_Block_Multiple
 {
+    /**
+     * Uploader block constructor
+     */
     public function __construct()
     {
         parent::__construct();
-        $params = $this->getConfig()->getParams();
         $type = $this->_getMediaType();
         $allowed = Mage::getSingleton('cms/wysiwyg_images_storage')->getAllowedExtensions($type);
-        $labels = array();
-        $files = array();
-        foreach ($allowed as $ext) {
-            $labels[] = '.' . $ext;
-            $files[] = '*.' . $ext;
-        }
-        $this->getConfig()
-            ->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload', array('type' => $type)))
-            ->setParams($params)
-            ->setFileField('image')
-            ->setFilters(array(
-                'images' => array(
-                    'label' => $this->helper('cms')->__('Images (%s)', implode(', ', $labels)),
-                    'files' => $files
-                )
+        $this->getUploaderConfig()
+            ->setFileParameterName('image')
+            ->setTarget(
+                Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload', array('type' => $type))
+            );
+        $this->getButtonConfig()
+            ->setAttributes(array(
+                'accept' => $this->getButtonConfig()->getMimeTypesByExtensions($allowed)
             ));
     }
 
diff --git app/code/core/Mage/Adminhtml/Block/Media/Uploader.php app/code/core/Mage/Adminhtml/Block/Media/Uploader.php
index 01be54c..455cdde 100644
--- app/code/core/Mage/Adminhtml/Block/Media/Uploader.php
+++ app/code/core/Mage/Adminhtml/Block/Media/Uploader.php
@@ -31,189 +31,20 @@
  * @package    Mage_Adminhtml
  * @author      Magento Core Team <core@magentocommerce.com>
  */
-class Mage_Adminhtml_Block_Media_Uploader extends Mage_Adminhtml_Block_Widget
-{
-
-    protected $_config;
-
-    public function __construct()
-    {
-        parent::__construct();
-        $this->setId($this->getId() . '_Uploader');
-        $this->setTemplate('media/uploader.phtml');
-        $this->getConfig()->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload'));
-        $this->getConfig()->setParams(array('form_key' => $this->getFormKey()));
-        $this->getConfig()->setFileField('file');
-        $this->getConfig()->setFilters(array(
-            'images' => array(
-                'label' => Mage::helper('adminhtml')->__('Images (.gif, .jpg, .png)'),
-                'files' => array('*.gif', '*.jpg', '*.png')
-            ),
-            'media' => array(
-                'label' => Mage::helper('adminhtml')->__('Media (.avi, .flv, .swf)'),
-                'files' => array('*.avi', '*.flv', '*.swf')
-            ),
-            'all'    => array(
-                'label' => Mage::helper('adminhtml')->__('All Files'),
-                'files' => array('*.*')
-            )
-        ));
-    }
-
-    protected function _prepareLayout()
-    {
-        $this->setChild(
-            'browse_button',
-            $this->getLayout()->createBlock('adminhtml/widget_button')
-                ->addData(array(
-                    'id'      => $this->_getButtonId('browse'),
-                    'label'   => Mage::helper('adminhtml')->__('Browse Files...'),
-                    'type'    => 'button',
-                    'onclick' => $this->getJsObjectName() . '.browse()'
-                ))
-        );
-
-        $this->setChild(
-            'upload_button',
-            $this->getLayout()->createBlock('adminhtml/widget_button')
-                ->addData(array(
-                    'id'      => $this->_getButtonId('upload'),
-                    'label'   => Mage::helper('adminhtml')->__('Upload Files'),
-                    'type'    => 'button',
-                    'onclick' => $this->getJsObjectName() . '.upload()'
-                ))
-        );
-
-        $this->setChild(
-            'delete_button',
-            $this->getLayout()->createBlock('adminhtml/widget_button')
-                ->addData(array(
-                    'id'      => '{{id}}-delete',
-                    'class'   => 'delete',
-                    'type'    => 'button',
-                    'label'   => Mage::helper('adminhtml')->__('Remove'),
-                    'onclick' => $this->getJsObjectName() . '.removeFile(\'{{fileId}}\')'
-                ))
-        );
-
-        return parent::_prepareLayout();
-    }
-
-    protected function _getButtonId($buttonName)
-    {
-        return $this->getHtmlId() . '-' . $buttonName;
-    }
-
-    public function getBrowseButtonHtml()
-    {
-        return $this->getChildHtml('browse_button');
-    }
-
-    public function getUploadButtonHtml()
-    {
-        return $this->getChildHtml('upload_button');
-    }
-
-    public function getDeleteButtonHtml()
-    {
-        return $this->getChildHtml('delete_button');
-    }
-
-    /**
-     * Retrive uploader js object name
-     *
-     * @return string
-     */
-    public function getJsObjectName()
-    {
-        return $this->getHtmlId() . 'JsObject';
-    }
-
-    /**
-     * Retrive config json
-     *
-     * @return string
-     */
-    public function getConfigJson()
-    {
-        return Mage::helper('core')->jsonEncode($this->getConfig()->getData());
-    }
-
-    /**
-     * Retrive config object
-     *
-     * @return Varien_Config
-     */
-    public function getConfig()
-    {
-        if(is_null($this->_config)) {
-            $this->_config = new Varien_Object();
-        }
-
-        return $this->_config;
-    }
-
-    public function getPostMaxSize()
-    {
-        return ini_get('post_max_size');
-    }
-
-    public function getUploadMaxSize()
-    {
-        return ini_get('upload_max_filesize');
-    }
-
-    public function getDataMaxSize()
-    {
-        return min($this->getPostMaxSize(), $this->getUploadMaxSize());
-    }
-
-    public function getDataMaxSizeInBytes()
-    {
-        $iniSize = $this->getDataMaxSize();
-        $size = substr($iniSize, 0, strlen($iniSize)-1);
-        $parsedSize = 0;
-        switch (strtolower(substr($iniSize, strlen($iniSize)-1))) {
-            case 't':
-                $parsedSize = $size*(1024*1024*1024*1024);
-                break;
-            case 'g':
-                $parsedSize = $size*(1024*1024*1024);
-                break;
-            case 'm':
-                $parsedSize = $size*(1024*1024);
-                break;
-            case 'k':
-                $parsedSize = $size*1024;
-                break;
-            case 'b':
-            default:
-                $parsedSize = $size;
-                break;
-        }
-        return $parsedSize;
-    }
 
+/**
+ * @deprecated
+ * Class Mage_Adminhtml_Block_Media_Uploader
+ */
+class Mage_Adminhtml_Block_Media_Uploader extends Mage_Uploader_Block_Multiple
+{
     /**
-     * Retrieve full uploader SWF's file URL
-     * Implemented to solve problem with cross domain SWFs
-     * Now uploader can be only in the same URL where backend located
-     *
-     * @param string $url url to uploader in current theme
-     *
-     * @return string full URL
+     * Constructor for uploader block
      */
-    public function getUploaderUrl($url)
+    public function __construct()
     {
-        if (!is_string($url)) {
-            $url = '';
-        }
-        $design = Mage::getDesign();
-        $theme = $design->getTheme('skin');
-        if (empty($url) || !$design->validateFile($url, array('_type' => 'skin', '_theme' => $theme))) {
-            $theme = $design->getDefaultTheme();
-        }
-        return Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB) . 'skin/' .
-            $design->getArea() . '/' . $design->getPackageName() . '/' . $theme . '/' . $url;
+        parent::__construct();
+        $this->getUploaderConfig()->setTarget(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload'));
+        $this->getUploaderConfig()->setFileParameterName('file');
     }
 }
diff --git app/code/core/Mage/Adminhtml/Block/Urlrewrite/Category/Tree.php app/code/core/Mage/Adminhtml/Block/Urlrewrite/Category/Tree.php
index 2abbd4c..3809e44 100644
--- app/code/core/Mage/Adminhtml/Block/Urlrewrite/Category/Tree.php
+++ app/code/core/Mage/Adminhtml/Block/Urlrewrite/Category/Tree.php
@@ -119,7 +119,7 @@ class Mage_Adminhtml_Block_Urlrewrite_Category_Tree extends Mage_Adminhtml_Block
             'parent_id'      => (int)$node->getParentId(),
             'children_count' => (int)$node->getChildrenCount(),
             'is_active'      => (bool)$node->getIsActive(),
-            'name'           => $node->getName(),
+            'name'           => $this->escapeHtml($node->getName()),
             'level'          => (int)$node->getLevel(),
             'product_count'  => (int)$node->getProductCount()
         );
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized.php
index 0695670..ba0565d 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized.php
@@ -29,8 +29,17 @@ class Mage_Adminhtml_Model_System_Config_Backend_Serialized extends Mage_Core_Mo
     protected function _afterLoad()
     {
         if (!is_array($this->getValue())) {
-            $value = $this->getValue();
-            $this->setValue(empty($value) ? false : unserialize($value));
+            $serializedValue = $this->getValue();
+            $unserializedValue = false;
+            if (!empty($serializedValue)) {
+                try {
+                    $unserializedValue = Mage::helper('core/unserializeArray')
+                        ->unserialize($serializedValue);
+                } catch (Exception $e) {
+                    Mage::logException($e);
+                }
+            }
+            $this->setValue($unserializedValue);
         }
     }
 
diff --git app/code/core/Mage/Adminhtml/controllers/DashboardController.php app/code/core/Mage/Adminhtml/controllers/DashboardController.php
index eebb471..952b7f7 100644
--- app/code/core/Mage/Adminhtml/controllers/DashboardController.php
+++ app/code/core/Mage/Adminhtml/controllers/DashboardController.php
@@ -91,7 +91,7 @@ class Mage_Adminhtml_DashboardController extends Mage_Adminhtml_Controller_Actio
         $gaHash = $this->getRequest()->getParam('h');
         if ($gaData && $gaHash) {
             $newHash = Mage::helper('adminhtml/dashboard_data')->getChartDataHash($gaData);
-            if ($newHash == $gaHash) {
+            if (hash_equals($newHash, $gaHash)) {
                 if ($params = unserialize(base64_decode(urldecode($gaData)))) {
                     $response = $httpClient->setUri(Mage_Adminhtml_Block_Dashboard_Graph::API_URL)
                             ->setParameterGet($params)
diff --git app/code/core/Mage/Adminhtml/controllers/IndexController.php app/code/core/Mage/Adminhtml/controllers/IndexController.php
index 9acadab..f10af88 100644
--- app/code/core/Mage/Adminhtml/controllers/IndexController.php
+++ app/code/core/Mage/Adminhtml/controllers/IndexController.php
@@ -392,7 +392,7 @@ class Mage_Adminhtml_IndexController extends Mage_Adminhtml_Controller_Action
         }
 
         $userToken = $user->getRpToken();
-        if (strcmp($userToken, $resetPasswordLinkToken) != 0 || $user->isResetPasswordLinkTokenExpired()) {
+        if (!hash_equals($userToken, $resetPasswordLinkToken) || $user->isResetPasswordLinkTokenExpired()) {
             throw Mage::exception('Mage_Core', Mage::helper('adminhtml')->__('Your password reset link has expired.'));
         }
     }
diff --git app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php
index 1305800..2358839 100644
--- app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php
+++ app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php
@@ -43,7 +43,7 @@ class Mage_Adminhtml_Media_UploaderController extends Mage_Adminhtml_Controller_
     {
         $this->loadLayout();
         $this->_addContent(
-            $this->getLayout()->createBlock('adminhtml/media_uploader')
+            $this->getLayout()->createBlock('uploader/multiple')
         );
         $this->renderLayout();
     }
diff --git app/code/core/Mage/Catalog/Block/Product/Abstract.php app/code/core/Mage/Catalog/Block/Product/Abstract.php
index 65efc78..2a61ae5 100644
--- app/code/core/Mage/Catalog/Block/Product/Abstract.php
+++ app/code/core/Mage/Catalog/Block/Product/Abstract.php
@@ -34,6 +34,11 @@
  */
 abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Template
 {
+    /**
+     * Price block array
+     *
+     * @var array
+     */
     protected $_priceBlock = array();
 
     /**
@@ -43,10 +48,25 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     protected $_block = 'catalog/product_price';
 
+    /**
+     * Price template
+     *
+     * @var string
+     */
     protected $_priceBlockDefaultTemplate = 'catalog/product/price.phtml';
 
+    /**
+     * Tier price template
+     *
+     * @var string
+     */
     protected $_tierPriceDefaultTemplate  = 'catalog/product/view/tierprices.phtml';
 
+    /**
+     * Price types
+     *
+     * @var array
+     */
     protected $_priceBlockTypes = array();
 
     /**
@@ -56,6 +76,11 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     protected $_useLinkForAsLowAs = true;
 
+    /**
+     * Review block instance
+     *
+     * @var null|Mage_Review_Block_Helper
+     */
     protected $_reviewsHelperBlock;
 
     /**
@@ -89,18 +114,33 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      */
     public function getAddToCartUrl($product, $additional = array())
     {
-        if ($product->getTypeInstance(true)->hasRequiredOptions($product)) {
-            if (!isset($additional['_escape'])) {
-                $additional['_escape'] = true;
-            }
-            if (!isset($additional['_query'])) {
-                $additional['_query'] = array();
-            }
-            $additional['_query']['options'] = 'cart';
-
-            return $this->getProductUrl($product, $additional);
+        if (!$product->getTypeInstance(true)->hasRequiredOptions($product)) {
+            return $this->helper('checkout/cart')->getAddUrl($product, $additional);
         }
-        return $this->helper('checkout/cart')->getAddUrl($product, $additional);
+        $additional = array_merge(
+            $additional,
+            array(Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey())
+        );
+        if (!isset($additional['_escape'])) {
+            $additional['_escape'] = true;
+        }
+        if (!isset($additional['_query'])) {
+            $additional['_query'] = array();
+        }
+        $additional['_query']['options'] = 'cart';
+        return $this->getProductUrl($product, $additional);
+    }
+
+    /**
+     * Return model instance
+     *
+     * @param string $className
+     * @param array $arguments
+     * @return Mage_Core_Model_Abstract
+     */
+    protected function _getSingletonModel($className, $arguments = array())
+    {
+        return Mage::getSingleton($className, $arguments);
     }
 
     /**
@@ -126,7 +166,7 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
     }
 
     /**
-     * Enter description here...
+     * Return link to Add to Wishlist
      *
      * @param Mage_Catalog_Model_Product $product
      * @return string
@@ -155,6 +195,12 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
         return null;
     }
 
+    /**
+     * Return price block
+     *
+     * @param string $productTypeId
+     * @return mixed
+     */
     protected function _getPriceBlock($productTypeId)
     {
         if (!isset($this->_priceBlock[$productTypeId])) {
@@ -169,6 +215,12 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
         return $this->_priceBlock[$productTypeId];
     }
 
+    /**
+     * Return Block template
+     *
+     * @param string $productTypeId
+     * @return string
+     */
     protected function _getPriceBlockTemplate($productTypeId)
     {
         if (isset($this->_priceBlockTypes[$productTypeId])) {
@@ -304,6 +356,11 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
         return $this->getData('product');
     }
 
+    /**
+     * Return tier price template
+     *
+     * @return mixed|string
+     */
     public function getTierPriceTemplate()
     {
         if (!$this->hasData('tier_price_template')) {
@@ -419,13 +476,13 @@ abstract class Mage_Catalog_Block_Product_Abstract extends Mage_Core_Block_Templ
      *
      * @return string
      */
-    public function getImageLabel($product=null, $mediaAttributeCode='image')
+    public function getImageLabel($product = null, $mediaAttributeCode = 'image')
     {
         if (is_null($product)) {
             $product = $this->getProduct();
         }
 
-        $label = $product->getData($mediaAttributeCode.'_label');
+        $label = $product->getData($mediaAttributeCode . '_label');
         if (empty($label)) {
             $label = $product->getName();
         }
diff --git app/code/core/Mage/Catalog/Block/Product/View.php app/code/core/Mage/Catalog/Block/Product/View.php
index 0a9e39c..0064add 100644
--- app/code/core/Mage/Catalog/Block/Product/View.php
+++ app/code/core/Mage/Catalog/Block/Product/View.php
@@ -61,7 +61,7 @@ class Mage_Catalog_Block_Product_View extends Mage_Catalog_Block_Product_Abstrac
             $currentCategory = Mage::registry('current_category');
             if ($keyword) {
                 $headBlock->setKeywords($keyword);
-            } elseif($currentCategory) {
+            } elseif ($currentCategory) {
                 $headBlock->setKeywords($product->getName());
             }
             $description = $product->getMetaDescription();
@@ -71,7 +71,7 @@ class Mage_Catalog_Block_Product_View extends Mage_Catalog_Block_Product_Abstrac
                 $headBlock->setDescription(Mage::helper('core/string')->substr($product->getDescription(), 0, 255));
             }
             if ($this->helper('catalog/product')->canUseCanonicalTag()) {
-                $params = array('_ignore_category'=>true);
+                $params = array('_ignore_category' => true);
                 $headBlock->addLinkRel('canonical', $product->getUrlModel()->getUrl($product, $params));
             }
         }
@@ -117,7 +117,7 @@ class Mage_Catalog_Block_Product_View extends Mage_Catalog_Block_Product_Abstrac
             return $this->getCustomAddToCartUrl();
         }
 
-        if ($this->getRequest()->getParam('wishlist_next')){
+        if ($this->getRequest()->getParam('wishlist_next')) {
             $additional['wishlist_next'] = 1;
         }
 
@@ -191,9 +191,9 @@ class Mage_Catalog_Block_Product_View extends Mage_Catalog_Block_Product_Abstrac
         );
 
         $responseObject = new Varien_Object();
-        Mage::dispatchEvent('catalog_product_view_config', array('response_object'=>$responseObject));
+        Mage::dispatchEvent('catalog_product_view_config', array('response_object' => $responseObject));
         if (is_array($responseObject->getAdditionalOptions())) {
-            foreach ($responseObject->getAdditionalOptions() as $option=>$value) {
+            foreach ($responseObject->getAdditionalOptions() as $option => $value) {
                 $config[$option] = $value;
             }
         }
diff --git app/code/core/Mage/Catalog/Helper/Image.php app/code/core/Mage/Catalog/Helper/Image.php
index c7f957d..8532dc1 100644
--- app/code/core/Mage/Catalog/Helper/Image.php
+++ app/code/core/Mage/Catalog/Helper/Image.php
@@ -31,6 +31,8 @@
  */
 class Mage_Catalog_Helper_Image extends Mage_Core_Helper_Abstract
 {
+    const XML_NODE_PRODUCT_MAX_DIMENSION = 'catalog/product_image/max_dimension';
+
     /**
      * Current model
      *
@@ -631,10 +633,16 @@ class Mage_Catalog_Helper_Image extends Mage_Core_Helper_Abstract
      * @throws Mage_Core_Exception
      */
     public function validateUploadFile($filePath) {
-        if (!getimagesize($filePath)) {
+        $maxDimension = Mage::getStoreConfig(self::XML_NODE_PRODUCT_MAX_DIMENSION);
+        $imageInfo = getimagesize($filePath);
+        if (!$imageInfo) {
             Mage::throwException($this->__('Disallowed file type.'));
         }
 
+        if ($imageInfo[0] > $maxDimension || $imageInfo[1] > $maxDimension) {
+            Mage::throwException($this->__('Disalollowed file format.'));
+        }
+
         $_processor = new Varien_Image($filePath);
         return $_processor->getMimeType() !== null;
     }
diff --git app/code/core/Mage/Catalog/Helper/Product/Compare.php app/code/core/Mage/Catalog/Helper/Product/Compare.php
index e445dc8..5cfc660 100644
--- app/code/core/Mage/Catalog/Helper/Product/Compare.php
+++ app/code/core/Mage/Catalog/Helper/Product/Compare.php
@@ -79,17 +79,17 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
      */
     public function getListUrl()
     {
-         $itemIds = array();
-         foreach ($this->getItemCollection() as $item) {
-             $itemIds[] = $item->getId();
-         }
+        $itemIds = array();
+        foreach ($this->getItemCollection() as $item) {
+            $itemIds[] = $item->getId();
+        }
 
-         $params = array(
-            'items'=>implode(',', $itemIds),
+        $params = array(
+            'items' => implode(',', $itemIds),
             Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl()
-         );
+        );
 
-         return $this->_getUrl('catalog/product_compare', $params);
+        return $this->_getUrl('catalog/product_compare', $params);
     }
 
     /**
@@ -102,7 +102,8 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
     {
         return array(
             'product' => $product->getId(),
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl()
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl(),
+            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
         );
     }
 
@@ -128,7 +129,8 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
         $beforeCompareUrl = Mage::getSingleton('catalog/session')->getBeforeCompareUrl();
 
         $params = array(
-            'product'=>$product->getId(),
+            'product' => $product->getId(),
+            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey(),
             Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($beforeCompareUrl)
         );
 
@@ -143,10 +145,11 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
      */
     public function getAddToCartUrl($product)
     {
-        $beforeCompareUrl = Mage::getSingleton('catalog/session')->getBeforeCompareUrl();
+        $beforeCompareUrl = $this->_getSingletonModel('catalog/session')->getBeforeCompareUrl();
         $params = array(
-            'product'=>$product->getId(),
-            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($beforeCompareUrl)
+            'product' => $product->getId(),
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl($beforeCompareUrl),
+            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
         );
 
         return $this->_getUrl('checkout/cart/add', $params);
@@ -161,7 +164,7 @@ class Mage_Catalog_Helper_Product_Compare extends Mage_Core_Helper_Url
     public function getRemoveUrl($item)
     {
         $params = array(
-            'product'=>$item->getId(),
+            'product' => $item->getId(),
             Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->getEncodedUrl()
         );
         return $this->_getUrl('catalog/product_compare/remove', $params);
diff --git app/code/core/Mage/Catalog/Model/Resource/Layer/Filter/Price.php app/code/core/Mage/Catalog/Model/Resource/Layer/Filter/Price.php
index 7e3919c..75f5fdd 100755
--- app/code/core/Mage/Catalog/Model/Resource/Layer/Filter/Price.php
+++ app/code/core/Mage/Catalog/Model/Resource/Layer/Filter/Price.php
@@ -269,7 +269,7 @@ class Mage_Catalog_Model_Resource_Layer_Filter_Price extends Mage_Core_Model_Res
             'range' => $rangeExpr,
             'count' => $countExpr
         ));
-        $select->group($rangeExpr)->order("$rangeExpr ASC");
+        $select->group('range')->order('range ' . Varien_Data_Collection::SORT_ORDER_ASC);
 
         return $this->_getReadAdapter()->fetchPairs($select);
     }
diff --git app/code/core/Mage/Catalog/controllers/Product/CompareController.php app/code/core/Mage/Catalog/controllers/Product/CompareController.php
index ca6101c..54aea41 100644
--- app/code/core/Mage/Catalog/controllers/Product/CompareController.php
+++ app/code/core/Mage/Catalog/controllers/Product/CompareController.php
@@ -74,6 +74,11 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
      */
     public function addAction()
     {
+        if (!$this->_validateFormKey()) {
+            $this->_redirectReferer();
+            return;
+        }
+
         $productId = (int) $this->getRequest()->getParam('product');
         if ($productId
             && (Mage::getSingleton('log/visitor')->getId() || Mage::getSingleton('customer/session')->isLoggedIn())
diff --git app/code/core/Mage/Catalog/etc/config.xml app/code/core/Mage/Catalog/etc/config.xml
index 3610e60..8099322 100644
--- app/code/core/Mage/Catalog/etc/config.xml
+++ app/code/core/Mage/Catalog/etc/config.xml
@@ -771,6 +771,9 @@
             <product>
                 <default_tax_group>2</default_tax_group>
             </product>
+            <product_image>
+                <max_dimension>5000</max_dimension>
+            </product_image>
             <seo>
                 <product_url_suffix>.html</product_url_suffix>
                 <category_url_suffix>.html</category_url_suffix>
diff --git app/code/core/Mage/Catalog/etc/system.xml app/code/core/Mage/Catalog/etc/system.xml
index 2cfad3d..fc2ca8e 100644
--- app/code/core/Mage/Catalog/etc/system.xml
+++ app/code/core/Mage/Catalog/etc/system.xml
@@ -185,6 +185,24 @@
                         </lines_perpage>
                     </fields>
                 </sitemap>
+                <product_image translate="label">
+                    <label>Product Image</label>
+                    <sort_order>200</sort_order>
+                    <show_in_default>1</show_in_default>
+                    <show_in_website>1</show_in_website>
+                    <show_in_store>1</show_in_store>
+                    <fields>
+                        <max_dimension translate="label comment">
+                            <label>Maximum resolution for upload image</label>
+                            <comment>Maximum width and height resolutions for upload image</comment>
+                            <frontend_type>text</frontend_type>
+                            <sort_order>10</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>1</show_in_store>
+                        </max_dimension>
+                    </fields>
+                </product_image>
                 <placeholder translate="label">
                     <label>Product Image Placeholders</label>
                     <clone_fields>1</clone_fields>
diff --git app/code/core/Mage/Centinel/Model/Api.php app/code/core/Mage/Centinel/Model/Api.php
index d32afce..de05f2d 100644
--- app/code/core/Mage/Centinel/Model/Api.php
+++ app/code/core/Mage/Centinel/Model/Api.php
@@ -25,11 +25,6 @@
  */
 
 /**
- * 3D Secure Validation Library for Payment
- */
-include_once '3Dsecure/CentinelClient.php';
-
-/**
  * 3D Secure Validation Api
  */
 class Mage_Centinel_Model_Api extends Varien_Object
@@ -73,19 +68,19 @@ class Mage_Centinel_Model_Api extends Varien_Object
     /**
      * Centinel validation client
      *
-     * @var CentinelClient
+     * @var Mage_Centinel_Model_Api_Client
      */
     protected $_clientInstance = null;
 
     /**
      * Return Centinel thin client object
      *
-     * @return CentinelClient
+     * @return Mage_Centinel_Model_Api_Client
      */
     protected function _getClientInstance()
     {
         if (empty($this->_clientInstance)) {
-            $this->_clientInstance = new CentinelClient();
+            $this->_clientInstance = new Mage_Centinel_Model_Api_Client();
         }
         return $this->_clientInstance;
     }
@@ -136,7 +131,7 @@ class Mage_Centinel_Model_Api extends Varien_Object
      * @param $method string
      * @param $data array
      *
-     * @return CentinelClient
+     * @return Mage_Centinel_Model_Api_Client
      */
     protected function _call($method, $data)
     {
diff --git app/code/core/Mage/Centinel/Model/Api/Client.php app/code/core/Mage/Centinel/Model/Api/Client.php
new file mode 100644
index 0000000..ae8dcaf
--- /dev/null
+++ app/code/core/Mage/Centinel/Model/Api/Client.php
@@ -0,0 +1,79 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Centinel
+ * @copyright Copyright (c) 2006-2014 X.commerce, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/**
+ * 3D Secure Validation Library for Payment
+ */
+include_once '3Dsecure/CentinelClient.php';
+
+/**
+ * 3D Secure Validation Api
+ */
+class Mage_Centinel_Model_Api_Client extends CentinelClient
+{
+    public function sendHttp($url, $connectTimeout = "", $timeout)
+    {
+        // verify that the URL uses a supported protocol.
+        if ((strpos($url, "http://") === 0) || (strpos($url, "https://") === 0)) {
+
+            //Construct the payload to POST to the url.
+            $data = $this->getRequestXml();
+
+            // create a new cURL resource
+            $ch = curl_init($url);
+
+            // set URL and other appropriate options
+            curl_setopt($ch, CURLOPT_POST ,1);
+            curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
+            curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
+            curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 1);
+            curl_setopt($ch, CURLOPT_TIMEOUT, $timeout);
+
+            // Execute the request.
+            $result = curl_exec($ch);
+            $succeeded = curl_errno($ch) == 0 ? true : false;
+
+            // close cURL resource, and free up system resources
+            curl_close($ch);
+
+            // If Communication was not successful set error result, otherwise
+            if (!$succeeded) {
+                $result = $this->setErrorResponse(CENTINEL_ERROR_CODE_8030, CENTINEL_ERROR_CODE_8030_DESC);
+            }
+
+            // Assert that we received an expected Centinel Message in reponse.
+            if (strpos($result, "<CardinalMPI>") === false) {
+                $result = $this->setErrorResponse(CENTINEL_ERROR_CODE_8010, CENTINEL_ERROR_CODE_8010_DESC);
+            }
+        } else {
+            $result = $this->setErrorResponse(CENTINEL_ERROR_CODE_8000, CENTINEL_ERROR_CODE_8000_DESC);
+        }
+        $parser = new XMLParser;
+        $parser->deserializeXml($result);
+        $this->response = $parser->deserializedResponse;
+    }
+}
diff --git app/code/core/Mage/Checkout/Helper/Cart.php app/code/core/Mage/Checkout/Helper/Cart.php
index 6e824a1..1617aef 100644
--- app/code/core/Mage/Checkout/Helper/Cart.php
+++ app/code/core/Mage/Checkout/Helper/Cart.php
@@ -31,6 +31,9 @@
  */
 class Mage_Checkout_Helper_Cart extends Mage_Core_Helper_Url
 {
+    /**
+     * Redirect to Cart path
+     */
     const XML_PATH_REDIRECT_TO_CART         = 'checkout/cart/redirect_to_cart';
 
     /**
@@ -47,16 +50,16 @@ class Mage_Checkout_Helper_Cart extends Mage_Core_Helper_Url
      * Retrieve url for add product to cart
      *
      * @param   Mage_Catalog_Model_Product $product
+     * @param array $additional
      * @return  string
      */
     public function getAddUrl($product, $additional = array())
     {
-        $continueUrl    = Mage::helper('core')->urlEncode($this->getCurrentUrl());
-        $urlParamName   = Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED;
-
         $routeParams = array(
-            $urlParamName   => $continueUrl,
-            'product'       => $product->getEntityId()
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $this->_getHelperInstance('core')
+                ->urlEncode($this->getCurrentUrl()),
+            'product' => $product->getEntityId(),
+            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
         );
 
         if (!empty($additional)) {
@@ -77,6 +80,17 @@ class Mage_Checkout_Helper_Cart extends Mage_Core_Helper_Url
     }
 
     /**
+     * Return helper instance
+     *
+     * @param  string $helperName
+     * @return Mage_Core_Helper_Abstract
+     */
+    protected function _getHelperInstance($helperName)
+    {
+        return Mage::helper($helperName);
+    }
+
+    /**
      * Retrieve url for remove product from cart
      *
      * @param   Mage_Sales_Quote_Item $item
@@ -85,7 +99,7 @@ class Mage_Checkout_Helper_Cart extends Mage_Core_Helper_Url
     public function getRemoveUrl($item)
     {
         $params = array(
-            'id'=>$item->getId(),
+            'id' => $item->getId(),
             Mage_Core_Controller_Front_Action::PARAM_NAME_BASE64_URL => $this->getCurrentBase64Url()
         );
         return $this->_getUrl('checkout/cart/delete', $params);
diff --git app/code/core/Mage/Checkout/controllers/CartController.php app/code/core/Mage/Checkout/controllers/CartController.php
index 3e4a7c7..36a7f35 100644
--- app/code/core/Mage/Checkout/controllers/CartController.php
+++ app/code/core/Mage/Checkout/controllers/CartController.php
@@ -70,6 +70,7 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
      * Set back redirect url to response
      *
      * @return Mage_Checkout_CartController
+     * @throws Mage_Exception
      */
     protected function _goBack()
     {
@@ -166,9 +167,15 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
 
     /**
      * Add product to shopping cart action
+     *
+     * @return void
      */
     public function addAction()
     {
+        if (!$this->_validateFormKey()) {
+            $this->_goBack();
+            return;
+        }
         $cart   = $this->_getCart();
         $params = $this->getRequest()->getParams();
         try {
@@ -207,7 +214,7 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
             );
 
             if (!$this->_getSession()->getNoCartRedirect(true)) {
-                if (!$cart->getQuote()->getHasError()){
+                if (!$cart->getQuote()->getHasError()) {
                     $message = $this->__('%s was added to your shopping cart.', Mage::helper('core')->escapeHtml($product->getName()));
                     $this->_getSession()->addSuccess($message);
                 }
@@ -236,34 +243,41 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
         }
     }
 
+    /**
+     * Add products in group to shopping cart action
+     */
     public function addgroupAction()
     {
         $orderItemIds = $this->getRequest()->getParam('order_items', array());
-        if (is_array($orderItemIds)) {
-            $itemsCollection = Mage::getModel('sales/order_item')
-                ->getCollection()
-                ->addIdFilter($orderItemIds)
-                ->load();
-            /* @var $itemsCollection Mage_Sales_Model_Mysql4_Order_Item_Collection */
-            $cart = $this->_getCart();
-            foreach ($itemsCollection as $item) {
-                try {
-                    $cart->addOrderItem($item, 1);
-                } catch (Mage_Core_Exception $e) {
-                    if ($this->_getSession()->getUseNotice(true)) {
-                        $this->_getSession()->addNotice($e->getMessage());
-                    } else {
-                        $this->_getSession()->addError($e->getMessage());
-                    }
-                } catch (Exception $e) {
-                    $this->_getSession()->addException($e, $this->__('Cannot add the item to shopping cart.'));
-                    Mage::logException($e);
-                    $this->_goBack();
+
+        if (!is_array($orderItemIds) || !$this->_validateFormKey()) {
+            $this->_goBack();
+            return;
+        }
+
+        $itemsCollection = Mage::getModel('sales/order_item')
+            ->getCollection()
+            ->addIdFilter($orderItemIds)
+            ->load();
+        /* @var $itemsCollection Mage_Sales_Model_Mysql4_Order_Item_Collection */
+        $cart = $this->_getCart();
+        foreach ($itemsCollection as $item) {
+            try {
+                $cart->addOrderItem($item, 1);
+            } catch (Mage_Core_Exception $e) {
+                if ($this->_getSession()->getUseNotice(true)) {
+                    $this->_getSession()->addNotice($e->getMessage());
+                } else {
+                    $this->_getSession()->addError($e->getMessage());
                 }
+            } catch (Exception $e) {
+                $this->_getSession()->addException($e, $this->__('Cannot add the item to shopping cart.'));
+                Mage::logException($e);
+                $this->_goBack();
             }
-            $cart->save();
-            $this->_getSession()->setCartWasUpdated(true);
         }
+        $cart->save();
+        $this->_getSession()->setCartWasUpdated(true);
         $this->_goBack();
     }
 
@@ -347,8 +361,8 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
                 array('item' => $item, 'request' => $this->getRequest(), 'response' => $this->getResponse())
             );
             if (!$this->_getSession()->getNoCartRedirect(true)) {
-                if (!$cart->getQuote()->getHasError()){
-                    $message = $this->__('%s was updated in your shopping cart.', Mage::helper('core')->htmlEscape($item->getProduct()->getName()));
+                if (!$cart->getQuote()->getHasError()) {
+                    $message = $this->__('%s was updated in your shopping cart.', Mage::helper('core')->escapeHtml($item->getProduct()->getName()));
                     $this->_getSession()->addSuccess($message);
                 }
                 $this->_goBack();
@@ -382,6 +396,11 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
      */
     public function updatePostAction()
     {
+        if (!$this->_validateFormKey()) {
+            $this->_redirect('*/*/');
+            return;
+        }
+
         $updateAction = (string)$this->getRequest()->getParam('update_cart_action');
 
         switch ($updateAction) {
@@ -492,6 +511,11 @@ class Mage_Checkout_CartController extends Mage_Core_Controller_Front_Action
         $this->_goBack();
     }
 
+    /**
+     * Estimate update action
+     *
+     * @return null
+     */
     public function estimateUpdatePostAction()
     {
         $code = (string) $this->getRequest()->getParam('estimate_method');
diff --git app/code/core/Mage/Checkout/controllers/OnepageController.php app/code/core/Mage/Checkout/controllers/OnepageController.php
index d56d263..2b8eec7 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -24,16 +24,27 @@
  * @license     http://www.magentocommerce.com/license/enterprise-edition
  */
 
-
+/**
+ * Class Onepage controller
+ */
 class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
 {
+    /**
+     * Functions for concrete method
+     *
+     * @var array
+     */
     protected $_sectionUpdateFunctions = array(
         'payment-method'  => '_getPaymentMethodsHtml',
         'shipping-method' => '_getShippingMethodsHtml',
         'review'          => '_getReviewHtml',
     );
 
-    /** @var Mage_Sales_Model_Order */
+    /**
+     * Order instance
+     *
+     * @var Mage_Sales_Model_Order
+     */
     protected $_order;
 
     /**
@@ -50,7 +61,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
             $checkoutSessionQuote->removeAllAddresses();
         }
 
-        if(!$this->_canShowForUnregisteredUsers()){
+        if (!$this->_canShowForUnregisteredUsers()) {
             $this->norouteAction();
             $this->setFlag('',self::FLAG_NO_DISPATCH,true);
             return;
@@ -59,6 +70,11 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         return $this;
     }
 
+    /**
+     * Send headers in case if session is expired
+     *
+     * @return Mage_Checkout_OnepageController
+     */
     protected function _ajaxRedirectResponse()
     {
         $this->getResponse()
@@ -123,6 +139,12 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         return $output;
     }
 
+    /**
+     * Return block content from the 'checkout_onepage_additional'
+     * This is the additional content for shipping method
+     *
+     * @return string
+     */
     protected function _getAdditionalHtml()
     {
         $layout = $this->getLayout();
@@ -180,7 +202,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
             return;
         }
         Mage::getSingleton('checkout/session')->setCartWasUpdated(false);
-        Mage::getSingleton('customer/session')->setBeforeAuthUrl(Mage::getUrl('*/*/*', array('_secure'=>true)));
+        Mage::getSingleton('customer/session')->setBeforeAuthUrl(Mage::getUrl('*/*/*', array('_secure' => true)));
         $this->getOnepage()->initCheckout();
         $this->loadLayout();
         $this->_initLayoutMessages('customer/session');
@@ -200,6 +222,9 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         $this->renderLayout();
     }
 
+    /**
+     * Shipping action
+     */
     public function shippingMethodAction()
     {
         if ($this->_expireAjax()) {
@@ -209,6 +234,9 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         $this->renderLayout();
     }
 
+    /**
+     * Review action
+     */
     public function reviewAction()
     {
         if ($this->_expireAjax()) {
@@ -244,6 +272,9 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
         $this->renderLayout();
     }
 
+    /**
+     * Failure action
+     */
     public function failureAction()
     {
         $lastQuoteId = $this->getOnepage()->getCheckout()->getLastQuoteId();
@@ -259,6 +290,9 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
     }
 
 
+    /**
+     * Additional action
+     */
     public function getAdditionalAction()
     {
         $this->getResponse()->setBody($this->_getAdditionalHtml());
@@ -383,10 +417,10 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
             /*
             $result will have erro data if shipping method is empty
             */
-            if(!$result) {
+            if (!$result) {
                 Mage::dispatchEvent('checkout_controller_onepage_save_shipping_method',
-                        array('request'=>$this->getRequest(),
-                            'quote'=>$this->getOnepage()->getQuote()));
+                    array('request' => $this->getRequest(),
+                        'quote' => $this->getOnepage()->getQuote()));
                 $this->getOnepage()->getQuote()->collectTotals();
                 $this->getResponse()->setBody(Mage::helper('core')->jsonEncode($result));
 
@@ -452,7 +486,8 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
     /**
      * Get Order by quoteId
      *
-     * @return Mage_Sales_Model_Order
+     * @return Mage_Core_Model_Abstract|Mage_Sales_Model_Order
+     * @throws Mage_Payment_Model_Info_Exception
      */
     protected function _getOrder()
     {
@@ -489,15 +524,21 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
      */
     public function saveOrderAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
+
         if ($this->_expireAjax()) {
             return;
         }
 
         $result = array();
         try {
-            if ($requiredAgreements = Mage::helper('checkout')->getRequiredAgreementIds()) {
+            $requiredAgreements = Mage::helper('checkout')->getRequiredAgreementIds();
+            if ($requiredAgreements) {
                 $postedAgreements = array_keys($this->getRequest()->getPost('agreement', array()));
-                if ($diff = array_diff($requiredAgreements, $postedAgreements)) {
+                $diff = array_diff($requiredAgreements, $postedAgreements);
+                if ($diff) {
                     $result['success'] = false;
                     $result['error'] = true;
                     $result['error_messages'] = $this->__('Please agree to all the terms and conditions before placing the order.');
@@ -515,7 +556,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
             $result['error']   = false;
         } catch (Mage_Payment_Model_Info_Exception $e) {
             $message = $e->getMessage();
-            if( !empty($message) ) {
+            if ( !empty($message) ) {
                 $result['error_messages'] = $message;
             }
             $result['goto_section'] = 'payment';
@@ -530,12 +571,13 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
             $result['error'] = true;
             $result['error_messages'] = $e->getMessage();
 
-            if ($gotoSection = $this->getOnepage()->getCheckout()->getGotoSection()) {
+            $gotoSection = $this->getOnepage()->getCheckout()->getGotoSection();
+            if ($gotoSection) {
                 $result['goto_section'] = $gotoSection;
                 $this->getOnepage()->getCheckout()->setGotoSection(null);
             }
-
-            if ($updateSection = $this->getOnepage()->getCheckout()->getUpdateSection()) {
+            $updateSection = $this->getOnepage()->getCheckout()->getUpdateSection();
+            if ($updateSection) {
                 if (isset($this->_sectionUpdateFunctions[$updateSection])) {
                     $updateSectionFunction = $this->_sectionUpdateFunctions[$updateSection];
                     $result['update_section'] = array(
diff --git app/code/core/Mage/Core/Block/Abstract.php app/code/core/Mage/Core/Block/Abstract.php
index 93fff12..17b135f 100644
--- app/code/core/Mage/Core/Block/Abstract.php
+++ app/code/core/Mage/Core/Block/Abstract.php
@@ -38,6 +38,10 @@
 abstract class Mage_Core_Block_Abstract extends Varien_Object
 {
     /**
+     * Prefix for cache key
+     */
+    const CACHE_KEY_PREFIX = 'BLOCK_';
+    /**
      * Cache group Tag
      */
     const CACHE_GROUP = 'block_html';
@@ -1233,7 +1237,13 @@ abstract class Mage_Core_Block_Abstract extends Varien_Object
     public function getCacheKey()
     {
         if ($this->hasData('cache_key')) {
-            return $this->getData('cache_key');
+            $cacheKey = $this->getData('cache_key');
+            if (strpos($cacheKey, self::CACHE_KEY_PREFIX) !== 0) {
+                $cacheKey = self::CACHE_KEY_PREFIX . $cacheKey;
+                $this->setData('cache_key', $cacheKey);
+            }
+
+            return $cacheKey;
         }
         /**
          * don't prevent recalculation by saving generated cache key
diff --git app/code/core/Mage/Core/Helper/Url.php app/code/core/Mage/Core/Helper/Url.php
index 358115a..88cdbb2 100644
--- app/code/core/Mage/Core/Helper/Url.php
+++ app/code/core/Mage/Core/Helper/Url.php
@@ -51,7 +51,7 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
             $port = (in_array($port, $defaultPorts)) ? '' : ':' . $port;
         }
         $url = $request->getScheme() . '://' . $request->getHttpHost() . $port . $request->getServer('REQUEST_URI');
-        return $url;
+        return $this->escapeUrl($url);
 //        return $this->_getUrl('*/*/*', array('_current' => true, '_use_rewrite' => true));
     }
 
@@ -65,7 +65,13 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
         return $this->urlEncode($this->getCurrentUrl());
     }
 
-    public function getEncodedUrl($url=null)
+    /**
+     * Return encoded url
+     *
+     * @param null|string $url
+     * @return string
+     */
+    public function getEncodedUrl($url = null)
     {
         if (!$url) {
             $url = $this->getCurrentUrl();
@@ -83,6 +89,12 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
         return Mage::getBaseUrl();
     }
 
+    /**
+     * Formatting string
+     *
+     * @param string $string
+     * @return string
+     */
     protected function _prepareString($string)
     {
         $string = preg_replace('#[^0-9a-z]+#i', '-', $string);
@@ -104,7 +116,7 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
         $startDelimiter = (false === strpos($url,'?'))? '?' : '&';
 
         $arrQueryParams = array();
-        foreach($param as $key=>$value) {
+        foreach ($param as $key => $value) {
             if (is_numeric($key) || is_object($value)) {
                 continue;
             }
@@ -128,6 +140,7 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
      *
      * @param string $url
      * @param string $paramKey
+     * @param boolean $caseSensitive
      * @return string
      */
     public function removeRequestParam($url, $paramKey, $caseSensitive = false)
@@ -143,4 +156,16 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
         }
         return $url;
     }
+
+    /**
+     * Return singleton model instance
+     *
+     * @param string $name
+     * @param array $arguments
+     * @return Mage_Core_Model_Abstract
+     */
+    protected function _getSingletonModel($name, $arguments = array())
+    {
+        return Mage::getSingleton($name, $arguments);
+    }
 }
diff --git app/code/core/Mage/Core/Model/Encryption.php app/code/core/Mage/Core/Model/Encryption.php
index 8d0167b..4c8da11 100644
--- app/code/core/Mage/Core/Model/Encryption.php
+++ app/code/core/Mage/Core/Model/Encryption.php
@@ -98,9 +98,9 @@ class Mage_Core_Model_Encryption
         $hashArr = explode(':', $hash);
         switch (count($hashArr)) {
             case 1:
-                return $this->hash($password) === $hash;
+                return hash_equals($this->hash($password), $hash);
             case 2:
-                return $this->hash($hashArr[1] . $password) === $hashArr[0];
+                return hash_equals($this->hash($hashArr[1] . $password),  $hashArr[0]);
         }
         Mage::throwException('Invalid hash.');
     }
diff --git app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
index d740759..51c7a9f 100644
--- app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
+++ app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
@@ -65,7 +65,13 @@ class Mage_Core_Model_Input_Filter_MaliciousCode implements Zend_Filter_Interfac
      */
     public function filter($value)
     {
-        return preg_replace($this->_expressions, '', $value);
+        $result = false;
+        do {
+            $subject = $result ? $result : $value;
+            $result = preg_replace($this->_expressions, '', $subject, -1, $count);
+        } while ($count !== 0);
+
+        return $result;
     }
 
     /**
diff --git app/code/core/Mage/Core/Model/Url.php app/code/core/Mage/Core/Model/Url.php
index 354d0fe..ab111cc 100644
--- app/code/core/Mage/Core/Model/Url.php
+++ app/code/core/Mage/Core/Model/Url.php
@@ -89,14 +89,31 @@ class Mage_Core_Model_Url extends Varien_Object
     const DEFAULT_ACTION_NAME       = 'index';
 
     /**
-     * Configuration paths
+     * XML base url path unsecure
      */
     const XML_PATH_UNSECURE_URL     = 'web/unsecure/base_url';
+
+    /**
+     * XML base url path secure
+     */
     const XML_PATH_SECURE_URL       = 'web/secure/base_url';
+
+    /**
+     * XML path for using in adminhtml
+     */
     const XML_PATH_SECURE_IN_ADMIN  = 'default/web/secure/use_in_adminhtml';
+
+    /**
+     * XML path for using in frontend
+     */
     const XML_PATH_SECURE_IN_FRONT  = 'web/secure/use_in_frontend';
 
     /**
+     * Param name for form key functionality
+     */
+    const FORM_KEY = 'form_key';
+
+    /**
      * Configuration data cache
      *
      * @var array
@@ -483,7 +500,7 @@ class Mage_Core_Model_Url extends Varien_Object
             }
             $routePath = $this->getActionPath();
             if ($this->getRouteParams()) {
-                foreach ($this->getRouteParams() as $key=>$value) {
+                foreach ($this->getRouteParams() as $key => $value) {
                     if (is_null($value) || false === $value || '' === $value || !is_scalar($value)) {
                         continue;
                     }
@@ -939,8 +956,8 @@ class Mage_Core_Model_Url extends Varien_Object
     /**
      * Build url by requested path and parameters
      *
-     * @param   string|null $routePath
-     * @param   array|null $routeParams
+     * @param string|null $routePath
+     * @param array|null $routeParams
      * @return  string
      */
     public function getUrl($routePath = null, $routeParams = null)
@@ -974,6 +991,7 @@ class Mage_Core_Model_Url extends Varien_Object
             $noSid = (bool)$routeParams['_nosid'];
             unset($routeParams['_nosid']);
         }
+
         $url = $this->getRouteUrl($routePath, $routeParams);
         /**
          * Apply query params, need call after getRouteUrl for rewrite _current values
@@ -1007,6 +1025,18 @@ class Mage_Core_Model_Url extends Varien_Object
     }
 
     /**
+     * Return singleton model instance
+     *
+     * @param string $name
+     * @param array $arguments
+     * @return Mage_Core_Model_Abstract
+     */
+    protected function _getSingletonModel($name, $arguments = array())
+    {
+        return Mage::getSingleton($name, $arguments);
+    }
+
+    /**
      * Check and add session id to URL
      *
      * @param string $url
diff --git app/code/core/Mage/Core/functions.php app/code/core/Mage/Core/functions.php
index 493d0d5..b41a457 100644
--- app/code/core/Mage/Core/functions.php
+++ app/code/core/Mage/Core/functions.php
@@ -375,3 +375,38 @@ if ( !function_exists('sys_get_temp_dir') ) {
         }
     }
 }
+
+if (!function_exists('hash_equals')) {
+    /**
+     * Compares two strings using the same time whether they're equal or not.
+     * A difference in length will leak
+     *
+     * @param string $known_string
+     * @param string $user_string
+     * @return boolean Returns true when the two strings are equal, false otherwise.
+     */
+    function hash_equals($known_string, $user_string)
+    {
+        $result = 0;
+
+        if (!is_string($known_string)) {
+            trigger_error("hash_equals(): Expected known_string to be a string", E_USER_WARNING);
+            return false;
+        }
+
+        if (!is_string($user_string)) {
+            trigger_error("hash_equals(): Expected user_string to be a string", E_USER_WARNING);
+            return false;
+        }
+
+        if (strlen($known_string) != strlen($user_string)) {
+            return false;
+        }
+
+        for ($i = 0; $i < strlen($known_string); $i++) {
+            $result |= (ord($known_string[$i]) ^ ord($user_string[$i]));
+        }
+
+        return 0 === $result;
+    }
+}
diff --git app/code/core/Mage/Customer/Block/Address/Book.php app/code/core/Mage/Customer/Block/Address/Book.php
index 20a507c..a27d073 100644
--- app/code/core/Mage/Customer/Block/Address/Book.php
+++ app/code/core/Mage/Customer/Block/Address/Book.php
@@ -56,7 +56,8 @@ class Mage_Customer_Block_Address_Book extends Mage_Core_Block_Template
 
     public function getDeleteUrl()
     {
-        return $this->getUrl('customer/address/delete');
+        return $this->getUrl('customer/address/delete',
+            array(Mage_Core_Model_Url::FORM_KEY => Mage::getSingleton('core/session')->getFormKey()));
     }
 
     public function getAddressEditUrl($address)
diff --git app/code/core/Mage/Customer/controllers/AccountController.php app/code/core/Mage/Customer/controllers/AccountController.php
index 4ce08af..65653c9 100644
--- app/code/core/Mage/Customer/controllers/AccountController.php
+++ app/code/core/Mage/Customer/controllers/AccountController.php
@@ -140,6 +140,11 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
      */
     public function loginPostAction()
     {
+        if (!$this->_validateFormKey()) {
+            $this->_redirect('*/*/');
+            return;
+        }
+
         if ($this->_getSession()->isLoggedIn()) {
             $this->_redirect('*/*/');
             return;
@@ -157,8 +162,8 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                 } catch (Mage_Core_Exception $e) {
                     switch ($e->getCode()) {
                         case Mage_Customer_Model_Customer::EXCEPTION_EMAIL_NOT_CONFIRMED:
-                            $value = Mage::helper('customer')->getEmailConfirmationUrl($login['username']);
-                            $message = Mage::helper('customer')->__('This account is not confirmed. <a href="%s">Click here</a> to resend confirmation email.', $value);
+                            $value = $this->_getHelper('customer')->getEmailConfirmationUrl($login['username']);
+                            $message = $this->_getHelper('customer')->__('This account is not confirmed. <a href="%s">Click here</a> to resend confirmation email.', $value);
                             break;
                         case Mage_Customer_Model_Customer::EXCEPTION_INVALID_EMAIL_OR_PASSWORD:
                             $message = $e->getMessage();
@@ -188,7 +193,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
 
         if (!$session->getBeforeAuthUrl() || $session->getBeforeAuthUrl() == Mage::getBaseUrl()) {
             // Set default URL to redirect customer to
-            $session->setBeforeAuthUrl(Mage::helper('customer')->getAccountUrl());
+            $session->setBeforeAuthUrl($this->_getHelper('customer')->getAccountUrl());
             // Redirect customer to the last page visited after logging in
             if ($session->isLoggedIn()) {
                 if (!Mage::getStoreConfigFlag(
@@ -197,8 +202,8 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     $referer = $this->getRequest()->getParam(Mage_Customer_Helper_Data::REFERER_QUERY_PARAM_NAME);
                     if ($referer) {
                         // Rebuild referer URL to handle the case when SID was changed
-                        $referer = Mage::getModel('core/url')
-                            ->getRebuiltUrl(Mage::helper('core')->urlDecode($referer));
+                        $referer = $this->_getModel('core/url')
+                            ->getRebuiltUrl($this->_getHelper('core')->urlDecode($referer));
                         if ($this->_isUrlInternal($referer)) {
                             $session->setBeforeAuthUrl($referer);
                         }
@@ -207,10 +212,10 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     $session->setBeforeAuthUrl($session->getAfterAuthUrl(true));
                 }
             } else {
-                $session->setBeforeAuthUrl(Mage::helper('customer')->getLoginUrl());
+                $session->setBeforeAuthUrl($this->_getHelper('customer')->getLoginUrl());
             }
-        } else if ($session->getBeforeAuthUrl() == Mage::helper('customer')->getLogoutUrl()) {
-            $session->setBeforeAuthUrl(Mage::helper('customer')->getDashboardUrl());
+        } else if ($session->getBeforeAuthUrl() == $this->_getHelper('customer')->getLogoutUrl()) {
+            $session->setBeforeAuthUrl($this->_getHelper('customer')->getDashboardUrl());
         } else {
             if (!$session->getAfterAuthUrl()) {
                 $session->setAfterAuthUrl($session->getBeforeAuthUrl());
@@ -267,125 +272,254 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             return;
         }
 
+        /** @var $session Mage_Customer_Model_Session */
         $session = $this->_getSession();
         if ($session->isLoggedIn()) {
             $this->_redirect('*/*/');
             return;
         }
 
-        if ($this->getRequest()->isPost()) {
-            $errors = array();
+        if (!$this->getRequest()->isPost()) {
+            $errUrl = $this->_getUrl('*/*/create', array('_secure' => true));
+            $this->_redirectError($errUrl);
+            return;
+        }
 
-            if (!$customer = Mage::registry('current_customer')) {
-                $customer = Mage::getModel('customer/customer')->setId(null);
+        $customer = $this->_getCustomer();
+
+        try {
+            $errors = $this->_getCustomerErrors($customer);
+
+            if (empty($errors)) {
+                $customer->save();
+                $this->_dispatchRegisterSuccess($customer);
+                $this->_successProcessRegistration($customer);
+                return;
+            } else {
+                $this->_addSessionError($errors);
+            }
+        } catch (Mage_Core_Exception $e) {
+            $session->setCustomerFormData($this->getRequest()->getPost());
+            if ($e->getCode() === Mage_Customer_Model_Customer::EXCEPTION_EMAIL_EXISTS) {
+                $url = $this->_getUrl('customer/account/forgotpassword');
+                $message = $this->__('There is already an account with this email address. If you are sure that it is your email address, <a href="%s">click here</a> to get your password and access your account.', $url);
+            } else {
+                $message = Mage::helper('core')->escapeHtml($e->getMessage());
             }
+            $session->addError($message);
+        } catch (Exception $e) {
+            $session->setCustomerFormData($this->getRequest()->getPost())
+                ->addException($e, $this->__('Cannot save the customer.'));
+        }
+        $url = $this->_getUrl('*/*/create', array('_secure' => true));
+        $this->_redirectError($url);
+    }
 
-            /* @var $customerForm Mage_Customer_Model_Form */
-            $customerForm = Mage::getModel('customer/form');
-            $customerForm->setFormCode('customer_account_create')
-                ->setEntity($customer);
+    /**
+     * Success Registration
+     *
+     * @param Mage_Customer_Model_Customer $customer
+     * @return Mage_Customer_AccountController
+     */
+    protected function _successProcessRegistration(Mage_Customer_Model_Customer $customer)
+    {
+        $session = $this->_getSession();
+        if ($customer->isConfirmationRequired()) {
+            /** @var $app Mage_Core_Model_App */
+            $app = $this->_getApp();
+            /** @var $store  Mage_Core_Model_Store*/
+            $store = $app->getStore();
+            $customer->sendNewAccountEmail(
+                'confirmation',
+                $session->getBeforeAuthUrl(),
+                $store->getId()
+            );
+            $customerHelper = $this->_getHelper('customer');
+            $session->addSuccess($this->__('Account confirmation is required. Please, check your email for the confirmation link. To resend the confirmation email please <a href="%s">click here</a>.',
+                $customerHelper->getEmailConfirmationUrl($customer->getEmail())));
+            $url = $this->_getUrl('*/*/index', array('_secure' => true));
+        } else {
+            $session->setCustomerAsLoggedIn($customer);
+            $session->renewSession();
+            $url = $this->_welcomeCustomer($customer);
+        }
+        $this->_redirectSuccess($url);
+        return $this;
+    }
 
-            $customerData = $customerForm->extractData($this->getRequest());
+    /**
+     * Get Customer Model
+     *
+     * @return Mage_Customer_Model_Customer
+     */
+    protected function _getCustomer()
+    {
+        $customer = $this->_getFromRegistry('current_customer');
+        if (!$customer) {
+            $customer = $this->_getModel('customer/customer')->setId(null);
+        }
+        if ($this->getRequest()->getParam('is_subscribed', false)) {
+            $customer->setIsSubscribed(1);
+        }
+        /**
+         * Initialize customer group id
+         */
+        $customer->getGroupId();
+
+        return $customer;
+    }
 
-            if ($this->getRequest()->getParam('is_subscribed', false)) {
-                $customer->setIsSubscribed(1);
+    /**
+     * Add session error method
+     *
+     * @param string|array $errors
+     */
+    protected function _addSessionError($errors)
+    {
+        $session = $this->_getSession();
+        $session->setCustomerFormData($this->getRequest()->getPost());
+        if (is_array($errors)) {
+            foreach ($errors as $errorMessage) {
+                $session->addError(Mage::helper('core')->escapeHtml($errorMessage));
             }
+        } else {
+            $session->addError($this->__('Invalid customer data'));
+        }
+    }
 
-            /**
-             * Initialize customer group id
-             */
-            $customer->getGroupId();
-
-            if ($this->getRequest()->getPost('create_address')) {
-                /* @var $address Mage_Customer_Model_Address */
-                $address = Mage::getModel('customer/address');
-                /* @var $addressForm Mage_Customer_Model_Form */
-                $addressForm = Mage::getModel('customer/form');
-                $addressForm->setFormCode('customer_register_address')
-                    ->setEntity($address);
-
-                $addressData    = $addressForm->extractData($this->getRequest(), 'address', false);
-                $addressErrors  = $addressForm->validateData($addressData);
-                if ($addressErrors === true) {
-                    $address->setId(null)
-                        ->setIsDefaultBilling($this->getRequest()->getParam('default_billing', false))
-                        ->setIsDefaultShipping($this->getRequest()->getParam('default_shipping', false));
-                    $addressForm->compactData($addressData);
-                    $customer->addAddress($address);
-
-                    $addressErrors = $address->validate();
-                    if (is_array($addressErrors)) {
-                        $errors = array_merge($errors, $addressErrors);
-                    }
-                } else {
-                    $errors = array_merge($errors, $addressErrors);
-                }
+    /**
+     * Validate customer data and return errors if they are
+     *
+     * @param Mage_Customer_Model_Customer $customer
+     * @return array|string
+     */
+    protected function _getCustomerErrors($customer)
+    {
+        $errors = array();
+        $request = $this->getRequest();
+        if ($request->getPost('create_address')) {
+            $errors = $this->_getErrorsOnCustomerAddress($customer);
+        }
+        $customerForm = $this->_getCustomerForm($customer);
+        $customerData = $customerForm->extractData($request);
+        $customerErrors = $customerForm->validateData($customerData);
+        if ($customerErrors !== true) {
+            $errors = array_merge($customerErrors, $errors);
+        } else {
+            $customerForm->compactData($customerData);
+            $customer->setPassword($request->getPost('password'));
+            $customer->setConfirmation($request->getPost('confirmation'));
+            $customerErrors = $customer->validate();
+            if (is_array($customerErrors)) {
+                $errors = array_merge($customerErrors, $errors);
             }
+        }
+        return $errors;
+    }
 
-            try {
-                $customerErrors = $customerForm->validateData($customerData);
-                if ($customerErrors !== true) {
-                    $errors = array_merge($customerErrors, $errors);
-                } else {
-                    $customerForm->compactData($customerData);
-                    $customer->setPassword($this->getRequest()->getPost('password'));
-                    $customer->setConfirmation($this->getRequest()->getPost('confirmation'));
-                    $customerErrors = $customer->validate();
-                    if (is_array($customerErrors)) {
-                        $errors = array_merge($customerErrors, $errors);
-                    }
-                }
+    /**
+     * Get Customer Form Initalized Model
+     *
+     * @param Mage_Customer_Model_Customer $customer
+     * @return Mage_Customer_Model_Form
+     */
+    protected function _getCustomerForm($customer)
+    {
+        /* @var $customerForm Mage_Customer_Model_Form */
+        $customerForm = $this->_getModel('customer/form');
+        $customerForm->setFormCode('customer_account_create');
+        $customerForm->setEntity($customer);
+        return $customerForm;
+    }
 
-                $validationResult = count($errors) == 0;
+    /**
+     * Get Helper
+     *
+     * @param string $path
+     * @return Mage_Core_Helper_Abstract
+     */
+    protected function _getHelper($path)
+    {
+        return Mage::helper($path);
+    }
 
-                if (true === $validationResult) {
-                    $customer->save();
+    /**
+     * Get App
+     *
+     * @return Mage_Core_Model_App
+     */
+    protected function _getApp()
+    {
+        return Mage::app();
+    }
 
-                    Mage::dispatchEvent('customer_register_success',
-                        array('account_controller' => $this, 'customer' => $customer)
-                    );
-
-                    if ($customer->isConfirmationRequired()) {
-                        $customer->sendNewAccountEmail(
-                            'confirmation',
-                            $session->getBeforeAuthUrl(),
-                            Mage::app()->getStore()->getId()
-                        );
-                        $session->addSuccess($this->__('Account confirmation is required. Please, check your email for the confirmation link. To resend the confirmation email please <a href="%s">click here</a>.', Mage::helper('customer')->getEmailConfirmationUrl($customer->getEmail())));
-                        $this->_redirectSuccess(Mage::getUrl('*/*/index', array('_secure'=>true)));
-                        return;
-                    } else {
-                        $session->setCustomerAsLoggedIn($customer);
-                        $url = $this->_welcomeCustomer($customer);
-                        $this->_redirectSuccess($url);
-                        return;
-                    }
-                } else {
-                    $session->setCustomerFormData($this->getRequest()->getPost());
-                    if (is_array($errors)) {
-                        foreach ($errors as $errorMessage) {
-                            $session->addError(Mage::helper('core')->escapeHtml($errorMessage));
-                        }
-                    } else {
-                        $session->addError($this->__('Invalid customer data'));
-                    }
-                }
-            } catch (Mage_Core_Exception $e) {
-                $session->setCustomerFormData($this->getRequest()->getPost());
-                if ($e->getCode() === Mage_Customer_Model_Customer::EXCEPTION_EMAIL_EXISTS) {
-                    $url = Mage::getUrl('customer/account/forgotpassword');
-                    $message = $this->__('There is already an account with this email address. If you are sure that it is your email address, <a href="%s">click here</a> to get your password and access your account.', $url);
-                } else {
-                    $message = Mage::helper('core')->escapeHtml($e->getMessage());
-                }
-                $session->addError($message);
-            } catch (Exception $e) {
-                $session->setCustomerFormData($this->getRequest()->getPost())
-                    ->addException($e, $this->__('Cannot save the customer.'));
-            }
+    /**
+     * Dispatch Event
+     *
+     * @param Mage_Customer_Model_Customer $customer
+     */
+    protected function _dispatchRegisterSuccess($customer)
+    {
+        Mage::dispatchEvent('customer_register_success',
+            array('account_controller' => $this, 'customer' => $customer)
+        );
+    }
+
+    /**
+     * Get errors on provided customer address
+     *
+     * @param Mage_Customer_Model_Customer $customer
+     * @return array $errors
+     */
+    protected function _getErrorsOnCustomerAddress($customer)
+    {
+        $errors = array();
+        /* @var $address Mage_Customer_Model_Address */
+        $address = $this->_getModel('customer/address');
+        /* @var $addressForm Mage_Customer_Model_Form */
+        $addressForm = $this->_getModel('customer/form');
+        $addressForm->setFormCode('customer_register_address')
+            ->setEntity($address);
+
+        $addressData = $addressForm->extractData($this->getRequest(), 'address', false);
+        $addressErrors = $addressForm->validateData($addressData);
+        if (is_array($addressErrors)) {
+            $errors = $addressErrors;
         }
+        $address->setId(null)
+            ->setIsDefaultBilling($this->getRequest()->getParam('default_billing', false))
+            ->setIsDefaultShipping($this->getRequest()->getParam('default_shipping', false));
+        $addressForm->compactData($addressData);
+        $customer->addAddress($address);
+
+        $addressErrors = $address->validate();
+        if (is_array($addressErrors)) {
+            $errors = array_merge($errors, $addressErrors);
+        }
+        return $errors;
+    }
 
-        $this->_redirectError(Mage::getUrl('*/*/create', array('_secure' => true)));
+    /**
+     * Get model by path
+     *
+     * @param string $path
+     * @param array|null $arguments
+     * @return false|Mage_Core_Model_Abstract
+     */
+    public function _getModel($path, $arguments = array())
+    {
+        return Mage::getModel($path, $arguments);
+    }
+
+    /**
+     * Get model from registry by path
+     *
+     * @param string $path
+     * @return mixed
+     */
+    protected function _getFromRegistry($path)
+    {
+        return Mage::registry($path);
     }
 
     /**
@@ -403,14 +537,16 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
         );
         if ($this->_isVatValidationEnabled()) {
             // Show corresponding VAT message to customer
-            $configAddressType = Mage::helper('customer/address')->getTaxCalculationAddressType();
+            $configAddressType = $this->_getHelper('customer/address')->getTaxCalculationAddressType();
             $userPrompt = '';
             switch ($configAddressType) {
                 case Mage_Customer_Model_Address_Abstract::TYPE_SHIPPING:
-                    $userPrompt = $this->__('If you are a registered VAT customer, please click <a href="%s">here</a> to enter you shipping address for proper VAT calculation', Mage::getUrl('customer/address/edit'));
+                    $userPrompt = $this->__('If you are a registered VAT customer, please click <a href="%s">here</a> to enter you shipping address for proper VAT calculation',
+                        $this->_getUrl('customer/address/edit'));
                     break;
                 default:
-                    $userPrompt = $this->__('If you are a registered VAT customer, please click <a href="%s">here</a> to enter you billing address for proper VAT calculation', Mage::getUrl('customer/address/edit'));
+                    $userPrompt = $this->__('If you are a registered VAT customer, please click <a href="%s">here</a> to enter you billing address for proper VAT calculation',
+                        $this->_getUrl('customer/address/edit'));
             }
             $this->_getSession()->addSuccess($userPrompt);
         }
@@ -421,7 +557,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             Mage::app()->getStore()->getId()
         );
 
-        $successUrl = Mage::getUrl('*/*/index', array('_secure'=>true));
+        $successUrl = $this->_getUrl('*/*/index', array('_secure' => true));
         if ($this->_getSession()->getBeforeAuthUrl()) {
             $successUrl = $this->_getSession()->getBeforeAuthUrl(true);
         }
@@ -433,7 +569,8 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
      */
     public function confirmAction()
     {
-        if ($this->_getSession()->isLoggedIn()) {
+        $session = $this->_getSession();
+        if ($session->isLoggedIn()) {
             $this->_redirect('*/*/');
             return;
         }
@@ -447,7 +584,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
 
             // load customer by id (try/catch in case if it throws exceptions)
             try {
-                $customer = Mage::getModel('customer/customer')->load($id);
+                $customer = $this->_getModel('customer/customer')->load($id);
                 if ((!$customer) || (!$customer->getId())) {
                     throw new Exception('Failed to load customer by id.');
                 }
@@ -471,21 +608,22 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     throw new Exception($this->__('Failed to confirm customer account.'));
                 }
 
+                $session->renewSession();
                 // log in and send greeting email, then die happy
-                $this->_getSession()->setCustomerAsLoggedIn($customer);
+                $session->setCustomerAsLoggedIn($customer);
                 $successUrl = $this->_welcomeCustomer($customer, true);
                 $this->_redirectSuccess($backUrl ? $backUrl : $successUrl);
                 return;
             }
 
             // die happy
-            $this->_redirectSuccess(Mage::getUrl('*/*/index', array('_secure'=>true)));
+            $this->_redirectSuccess($this->_getUrl('*/*/index', array('_secure' => true)));
             return;
         }
         catch (Exception $e) {
             // die unhappy
             $this->_getSession()->addError($e->getMessage());
-            $this->_redirectError(Mage::getUrl('*/*/index', array('_secure'=>true)));
+            $this->_redirectError($this->_getUrl('*/*/index', array('_secure' => true)));
             return;
         }
     }
@@ -495,7 +633,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
      */
     public function confirmationAction()
     {
-        $customer = Mage::getModel('customer/customer');
+        $customer = $this->_getModel('customer/customer');
         if ($this->_getSession()->isLoggedIn()) {
             $this->_redirect('*/*/');
             return;
@@ -516,10 +654,10 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     $this->_getSession()->addSuccess($this->__('This email does not require confirmation.'));
                 }
                 $this->_getSession()->setUsername($email);
-                $this->_redirectSuccess(Mage::getUrl('*/*/index', array('_secure' => true)));
+                $this->_redirectSuccess($this->_getUrl('*/*/index', array('_secure' => true)));
             } catch (Exception $e) {
                 $this->_getSession()->addException($e, $this->__('Wrong email.'));
-                $this->_redirectError(Mage::getUrl('*/*/*', array('email' => $email, '_secure' => true)));
+                $this->_redirectError($this->_getUrl('*/*/*', array('email' => $email, '_secure' => true)));
             }
             return;
         }
@@ -535,6 +673,18 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
     }
 
     /**
+     * Get Url method
+     *
+     * @param string $url
+     * @param array $params
+     * @return string
+     */
+    protected function _getUrl($url, $params = array())
+    {
+        return Mage::getUrl($url, $params);
+    }
+
+    /**
      * Forgot customer password page
      */
     public function forgotPasswordAction()
@@ -565,13 +715,13 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             }
 
             /** @var $customer Mage_Customer_Model_Customer */
-            $customer = Mage::getModel('customer/customer')
+            $customer = $this->_getModel('customer/customer')
                 ->setWebsiteId(Mage::app()->getStore()->getWebsiteId())
                 ->loadByEmail($email);
 
             if ($customer->getId()) {
                 try {
-                    $newResetPasswordLinkToken = Mage::helper('customer')->generateResetPasswordLinkToken();
+                    $newResetPasswordLinkToken = $this->_getHelper('customer')->generateResetPasswordLinkToken();
                     $customer->changeResetPasswordLinkToken($newResetPasswordLinkToken);
                     $customer->sendPasswordResetConfirmationEmail();
                 } catch (Exception $exception) {
@@ -581,7 +731,9 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                 }
             }
             $this->_getSession()
-                ->addSuccess(Mage::helper('customer')->__('If there is an account associated with %s you will receive an email with a link to reset your password.', Mage::helper('customer')->htmlEscape($email)));
+                ->addSuccess($this->_getHelper('customer')
+                    ->__('If there is an account associated with %s you will receive an email with a link to reset your password.',
+                        $this->_getHelper('customer')->escapeHtml($email)));
             $this->_redirect('*/*/');
             return;
         } else {
@@ -626,16 +778,14 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                 ->_redirect('*/*/changeforgotten');
 
         } catch (Exception $exception) {
-            $this->_getSession()->addError(Mage::helper('customer')->__('Your password reset link has expired.'));
+            $this->_getSession()->addError($this->_getHelper('customer')->__('Your password reset link has expired.'));
             $this->_redirect('*/*/forgotpassword');
         }
     }
 
     /**
      * Reset forgotten password
-     *
      * Used to handle data recieved from reset forgotten password form
-     *
      */
     public function resetPasswordPostAction()
     {
@@ -646,17 +796,17 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
         try {
             $this->_validateResetPasswordLinkToken($customerId, $resetPasswordLinkToken);
         } catch (Exception $exception) {
-            $this->_getSession()->addError(Mage::helper('customer')->__('Your password reset link has expired.'));
+            $this->_getSession()->addError($this->_getHelper('customer')->__('Your password reset link has expired.'));
             $this->_redirect('*/*/');
             return;
         }
 
         $errorMessages = array();
         if (iconv_strlen($password) <= 0) {
-            array_push($errorMessages, Mage::helper('customer')->__('New password field cannot be empty.'));
+            array_push($errorMessages, $this->_getHelper('customer')->__('New password field cannot be empty.'));
         }
         /** @var $customer Mage_Customer_Model_Customer */
-        $customer = Mage::getModel('customer/customer')->load($customerId);
+        $customer = $this->_getModel('customer/customer')->load($customerId);
 
         $customer->setPassword($password);
         $customer->setConfirmation($passwordConfirmation);
@@ -684,7 +834,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             $this->_getSession()->unsetData(self::TOKEN_SESSION_NAME);
             $this->_getSession()->unsetData(self::CUSTOMER_ID_SESSION_NAME);
 
-            $this->_getSession()->addSuccess(Mage::helper('customer')->__('Your password has been updated.'));
+            $this->_getSession()->addSuccess($this->_getHelper('customer')->__('Your password has been updated.'));
             $this->_redirect('*/*/login');
         } catch (Exception $exception) {
             $this->_getSession()->addException($exception, $this->__('Cannot save a new password.'));
@@ -708,18 +858,18 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             || empty($customerId)
             || $customerId < 0
         ) {
-            throw Mage::exception('Mage_Core', Mage::helper('customer')->__('Invalid password reset token.'));
+            throw Mage::exception('Mage_Core', $this->_getHelper('customer')->__('Invalid password reset token.'));
         }
 
         /** @var $customer Mage_Customer_Model_Customer */
-        $customer = Mage::getModel('customer/customer')->load($customerId);
+        $customer = $this->_getModel('customer/customer')->load($customerId);
         if (!$customer || !$customer->getId()) {
-            throw Mage::exception('Mage_Core', Mage::helper('customer')->__('Wrong customer account specified.'));
+            throw Mage::exception('Mage_Core', $this->_getHelper('customer')->__('Wrong customer account specified.'));
         }
 
         $customerToken = $customer->getRpToken();
         if (strcmp($customerToken, $resetPasswordLinkToken) != 0 || $customer->isResetPasswordLinkTokenExpired()) {
-            throw Mage::exception('Mage_Core', Mage::helper('customer')->__('Your password reset link has expired.'));
+            throw Mage::exception('Mage_Core', $this->_getHelper('customer')->__('Your password reset link has expired.'));
         }
     }
 
@@ -741,7 +891,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
         if (!empty($data)) {
             $customer->addData($data);
         }
-        if ($this->getRequest()->getParam('changepass')==1){
+        if ($this->getRequest()->getParam('changepass') == 1) {
             $customer->setChangePassword(1);
         }
 
@@ -764,7 +914,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
             $customer = $this->_getSession()->getCustomer();
 
             /** @var $customerForm Mage_Customer_Model_Form */
-            $customerForm = Mage::getModel('customer/form');
+            $customerForm = $this->_getModel('customer/form');
             $customerForm->setFormCode('customer_account_edit')
                 ->setEntity($customer);
 
@@ -785,7 +935,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
                     $confPass   = $this->getRequest()->getPost('confirmation');
 
                     $oldPass = $this->_getSession()->getCustomer()->getPasswordHash();
-                    if (Mage::helper('core/string')->strpos($oldPass, ':')) {
+                    if ($this->_getHelper('core/string')->strpos($oldPass, ':')) {
                         list($_salt, $salt) = explode(':', $oldPass);
                     } else {
                         $salt = false;
@@ -863,7 +1013,7 @@ class Mage_Customer_AccountController extends Mage_Core_Controller_Front_Action
      */
     protected function _isVatValidationEnabled($store = null)
     {
-        return Mage::helper('customer/address')->isVatValidationEnabled($store);
+        return $this->_getHelper('customer/address')->isVatValidationEnabled($store);
     }
 
     /**
diff --git app/code/core/Mage/Customer/controllers/AddressController.php app/code/core/Mage/Customer/controllers/AddressController.php
index 24ddc57..394b7cc 100644
--- app/code/core/Mage/Customer/controllers/AddressController.php
+++ app/code/core/Mage/Customer/controllers/AddressController.php
@@ -163,6 +163,9 @@ class Mage_Customer_AddressController extends Mage_Core_Controller_Front_Action
 
     public function deleteAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*/');
+        }
         $addressId = $this->getRequest()->getParam('id', false);
 
         if ($addressId) {
diff --git app/code/core/Mage/Dataflow/Model/Profile.php app/code/core/Mage/Dataflow/Model/Profile.php
index 48edf85..d885bd9 100644
--- app/code/core/Mage/Dataflow/Model/Profile.php
+++ app/code/core/Mage/Dataflow/Model/Profile.php
@@ -64,10 +64,14 @@ class Mage_Dataflow_Model_Profile extends Mage_Core_Model_Abstract
 
     protected function _afterLoad()
     {
+        $guiData = '';
         if (is_string($this->getGuiData())) {
-            $guiData = unserialize($this->getGuiData());
-        } else {
-            $guiData = '';
+            try {
+                $guiData = Mage::helper('core/unserializeArray')
+                    ->unserialize($this->getGuiData());
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
         }
         $this->setGuiData($guiData);
 
@@ -127,7 +131,13 @@ class Mage_Dataflow_Model_Profile extends Mage_Core_Model_Abstract
     protected function _afterSave()
     {
         if (is_string($this->getGuiData())) {
-            $this->setGuiData(unserialize($this->getGuiData()));
+            try {
+                $guiData = Mage::helper('core/unserializeArray')
+                    ->unserialize($this->getGuiData());
+                $this->setGuiData($guiData);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
         }
 
         $profileHistory = Mage::getModel('dataflow/profile_history');
diff --git app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php
index 4f01025..f2e7698 100644
--- app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php
+++ app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php
@@ -32,7 +32,7 @@
  * @author      Magento Core Team <core@magentocommerce.com>
  */
 class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Links
-    extends Mage_Adminhtml_Block_Template
+    extends Mage_Uploader_Block_Single
 {
     /**
      * Purchased Separately Attribute cache
@@ -245,6 +245,7 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Li
      */
      protected function _prepareLayout()
     {
+        parent::_prepareLayout();
         $this->setChild(
             'upload_button',
             $this->getLayout()->createBlock('adminhtml/widget_button')->addData(array(
@@ -254,6 +255,10 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Li
                 'onclick' => 'Downloadable.massUploadByType(\'links\');Downloadable.massUploadByType(\'linkssample\')'
             ))
         );
+        $this->_addElementIdsMapping(array(
+            'container' => $this->getHtmlId() . '-new',
+            'delete'    => $this->getHtmlId() . '-delete'
+        ));
     }
 
     /**
@@ -273,33 +278,56 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Li
      */
     public function getConfigJson($type='links')
     {
-        $this->getConfig()->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()
-            ->getUrl('*/downloadable_file/upload', array('type' => $type, '_secure' => true)));
-        $this->getConfig()->setParams(array('form_key' => $this->getFormKey()));
-        $this->getConfig()->setFileField($type);
-        $this->getConfig()->setFilters(array(
-            'all'    => array(
-                'label' => Mage::helper('adminhtml')->__('All Files'),
-                'files' => array('*.*')
+
+        $this->getUploaderConfig()
+            ->setFileParameterName($type)
+            ->setTarget(
+                Mage::getModel('adminhtml/url')
+                    ->addSessionParam()
+                    ->getUrl('*/downloadable_file/upload', array('type' => $type, '_secure' => true))
+            );
+        $this->getMiscConfig()
+            ->setReplaceBrowseWithRemove(true)
+        ;
+        return Mage::helper('core')->jsonEncode(parent::getJsonConfig());
+    }
+
+    /**
+     * @return string
+     */
+    public function getBrowseButtonHtml($type = '')
+    {
+        return $this->getChild('browse_button')
+            // Workaround for IE9
+            ->setBeforeHtml(
+                '<div style="display:inline-block; " id="downloadable_link_{{id}}_' . $type . 'file-browse">'
             )
-        ));
-        $this->getConfig()->setReplaceBrowseWithRemove(true);
-        $this->getConfig()->setWidth('32');
-        $this->getConfig()->setHideUploadButton(true);
-        return Mage::helper('core')->jsonEncode($this->getConfig()->getData());
+            ->setAfterHtml('</div>')
+            ->setId('downloadable_link_{{id}}_' . $type . 'file-browse_button')
+            ->toHtml();
     }
 
+
     /**
-     * Retrive config object
+     * @return string
+     */
+    public function getDeleteButtonHtml($type = '')
+    {
+        return $this->getChild('delete_button')
+            ->setLabel('')
+            ->setId('downloadable_link_{{id}}_' . $type . 'file-delete')
+            ->setStyle('display:none; width:31px;')
+            ->toHtml();
+    }
+
+    /**
+     * Retrieve config object
      *
-     * @return Varien_Config
+     * @deprecated
+     * @return $this
      */
     public function getConfig()
     {
-        if(is_null($this->_config)) {
-            $this->_config = new Varien_Object();
-        }
-
-        return $this->_config;
+        return $this;
     }
 }
diff --git app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Samples.php app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Samples.php
index 43937f2..c21af62 100644
--- app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Samples.php
+++ app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Samples.php
@@ -32,7 +32,7 @@
  * @author      Magento Core Team <core@magentocommerce.com>
  */
 class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Samples
-    extends Mage_Adminhtml_Block_Widget
+    extends Mage_Uploader_Block_Single
 {
     /**
      * Class constructor
@@ -148,6 +148,7 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Sa
      */
     protected function _prepareLayout()
     {
+        parent::_prepareLayout();
         $this->setChild(
             'upload_button',
             $this->getLayout()->createBlock('adminhtml/widget_button')
@@ -158,6 +159,11 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Sa
                     'onclick' => 'Downloadable.massUploadByType(\'samples\')'
                 ))
         );
+
+        $this->_addElementIdsMapping(array(
+            'container' => $this->getHtmlId() . '-new',
+            'delete'    => $this->getHtmlId() . '-delete'
+        ));
     }
 
     /**
@@ -171,40 +177,59 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Sa
     }
 
     /**
-     * Retrive config json
+     * Retrieve config json
      *
      * @return string
      */
     public function getConfigJson()
     {
-        $this->getConfig()->setUrl(Mage::getModel('adminhtml/url')
-            ->addSessionParam()
-            ->getUrl('*/downloadable_file/upload', array('type' => 'samples', '_secure' => true)));
-        $this->getConfig()->setParams(array('form_key' => $this->getFormKey()));
-        $this->getConfig()->setFileField('samples');
-        $this->getConfig()->setFilters(array(
-            'all'    => array(
-                'label' => Mage::helper('adminhtml')->__('All Files'),
-                'files' => array('*.*')
-            )
-        ));
-        $this->getConfig()->setReplaceBrowseWithRemove(true);
-        $this->getConfig()->setWidth('32');
-        $this->getConfig()->setHideUploadButton(true);
-        return Mage::helper('core')->jsonEncode($this->getConfig()->getData());
+        $this->getUploaderConfig()
+            ->setFileParameterName('samples')
+            ->setTarget(
+                Mage::getModel('adminhtml/url')
+                    ->addSessionParam()
+                    ->getUrl('*/downloadable_file/upload', array('type' => 'samples', '_secure' => true))
+            );
+        $this->getMiscConfig()
+            ->setReplaceBrowseWithRemove(true)
+        ;
+        return Mage::helper('core')->jsonEncode(parent::getJsonConfig());
     }
 
     /**
-     * Retrive config object
+     * @return string
+     */
+    public function getBrowseButtonHtml()
+    {
+        return $this->getChild('browse_button')
+            // Workaround for IE9
+            ->setBeforeHtml('<div style="display:inline-block; " id="downloadable_sample_{{id}}_file-browse">')
+            ->setAfterHtml('</div>')
+            ->setId('downloadable_sample_{{id}}_file-browse_button')
+            ->toHtml();
+    }
+
+
+    /**
+     * @return string
+     */
+    public function getDeleteButtonHtml()
+    {
+        return $this->getChild('delete_button')
+            ->setLabel('')
+            ->setId('downloadable_sample_{{id}}_file-delete')
+            ->setStyle('display:none; width:31px;')
+            ->toHtml();
+    }
+
+    /**
+     * Retrieve config object
      *
-     * @return Varien_Config
+     * @deprecated
+     * @return $this
      */
     public function getConfig()
     {
-        if(is_null($this->_config)) {
-            $this->_config = new Varien_Object();
-        }
-
-        return $this->_config;
+        return $this;
     }
 }
diff --git app/code/core/Mage/Downloadable/Helper/File.php app/code/core/Mage/Downloadable/Helper/File.php
index eb7a190..2d2ce84 100644
--- app/code/core/Mage/Downloadable/Helper/File.php
+++ app/code/core/Mage/Downloadable/Helper/File.php
@@ -33,15 +33,35 @@
  */
 class Mage_Downloadable_Helper_File extends Mage_Core_Helper_Abstract
 {
+    /**
+     * @see Mage_Uploader_Helper_File::getMimeTypes
+     * @var array
+     */
+    protected $_mimeTypes;
+
+    /**
+     * @var Mage_Uploader_Helper_File
+     */
+    protected $_fileHelper;
+
+    /**
+     * Populate self::_mimeTypes array with values that set in config or pre-defined
+     */
     public function __construct()
     {
-        $nodes = Mage::getConfig()->getNode('global/mime/types');
-        if ($nodes) {
-            $nodes = (array)$nodes;
-            foreach ($nodes as $key => $value) {
-                self::$_mimeTypes[$key] = $value;
-            }
+        $this->_mimeTypes = $this->_getFileHelper()->getMimeTypes();
+    }
+
+    /**
+     * @return Mage_Uploader_Helper_File
+     */
+    protected function _getFileHelper()
+    {
+        if (!$this->_fileHelper) {
+            $this->_fileHelper = Mage::helper('uploader/file');
         }
+
+        return $this->_fileHelper;
     }
 
     /**
@@ -152,628 +172,48 @@ class Mage_Downloadable_Helper_File extends Mage_Core_Helper_Abstract
         return $file;
     }
 
+    /**
+     * Get MIME type for $filePath
+     *
+     * @param $filePath
+     * @return string
+     */
     public function getFileType($filePath)
     {
         $ext = substr($filePath, strrpos($filePath, '.')+1);
         return $this->_getFileTypeByExt($ext);
     }
 
+    /**
+     * Get MIME type by file extension
+     *
+     * @param $ext
+     * @return string
+     * @deprecated
+     */
     protected function _getFileTypeByExt($ext)
     {
-        $type = 'x' . $ext;
-        if (isset(self::$_mimeTypes[$type])) {
-            return self::$_mimeTypes[$type];
-        }
-        return 'application/octet-stream';
+        return $this->_getFileHelper()->getMimeTypeByExtension($ext);
     }
 
+    /**
+     * Get all MIME types
+     *
+     * @return array
+     */
     public function getAllFileTypes()
     {
-        return array_values(self::getAllMineTypes());
+        return array_values($this->getAllMineTypes());
     }
 
+    /**
+     * Get list of all MIME types
+     *
+     * @return array
+     */
     public function getAllMineTypes()
     {
-        return self::$_mimeTypes;
+        return $this->_mimeTypes;
     }
 
-    protected static $_mimeTypes =
-        array(
-            'x123' => 'application/vnd.lotus-1-2-3',
-            'x3dml' => 'text/vnd.in3d.3dml',
-            'x3g2' => 'video/3gpp2',
-            'x3gp' => 'video/3gpp',
-            'xace' => 'application/x-ace-compressed',
-            'xacu' => 'application/vnd.acucobol',
-            'xaep' => 'application/vnd.audiograph',
-            'xai' => 'application/postscript',
-            'xaif' => 'audio/x-aiff',
-
-            'xaifc' => 'audio/x-aiff',
-            'xaiff' => 'audio/x-aiff',
-            'xami' => 'application/vnd.amiga.ami',
-            'xapr' => 'application/vnd.lotus-approach',
-            'xasf' => 'video/x-ms-asf',
-            'xaso' => 'application/vnd.accpac.simply.aso',
-            'xasx' => 'video/x-ms-asf',
-            'xatom' => 'application/atom+xml',
-            'xatomcat' => 'application/atomcat+xml',
-
-            'xatomsvc' => 'application/atomsvc+xml',
-            'xatx' => 'application/vnd.antix.game-component',
-            'xau' => 'audio/basic',
-            'xavi' => 'video/x-msvideo',
-            'xbat' => 'application/x-msdownload',
-            'xbcpio' => 'application/x-bcpio',
-            'xbdm' => 'application/vnd.syncml.dm+wbxml',
-            'xbh2' => 'application/vnd.fujitsu.oasysprs',
-            'xbmi' => 'application/vnd.bmi',
-
-            'xbmp' => 'image/bmp',
-            'xbox' => 'application/vnd.previewsystems.box',
-            'xboz' => 'application/x-bzip2',
-            'xbtif' => 'image/prs.btif',
-            'xbz' => 'application/x-bzip',
-            'xbz2' => 'application/x-bzip2',
-            'xcab' => 'application/vnd.ms-cab-compressed',
-            'xccxml' => 'application/ccxml+xml',
-            'xcdbcmsg' => 'application/vnd.contact.cmsg',
-
-            'xcdkey' => 'application/vnd.mediastation.cdkey',
-            'xcdx' => 'chemical/x-cdx',
-            'xcdxml' => 'application/vnd.chemdraw+xml',
-            'xcdy' => 'application/vnd.cinderella',
-            'xcer' => 'application/pkix-cert',
-            'xcgm' => 'image/cgm',
-            'xchat' => 'application/x-chat',
-            'xchm' => 'application/vnd.ms-htmlhelp',
-            'xchrt' => 'application/vnd.kde.kchart',
-
-            'xcif' => 'chemical/x-cif',
-            'xcii' => 'application/vnd.anser-web-certificate-issue-initiation',
-            'xcil' => 'application/vnd.ms-artgalry',
-            'xcla' => 'application/vnd.claymore',
-            'xclkk' => 'application/vnd.crick.clicker.keyboard',
-            'xclkp' => 'application/vnd.crick.clicker.palette',
-            'xclkt' => 'application/vnd.crick.clicker.template',
-            'xclkw' => 'application/vnd.crick.clicker.wordbank',
-            'xclkx' => 'application/vnd.crick.clicker',
-
-            'xclp' => 'application/x-msclip',
-            'xcmc' => 'application/vnd.cosmocaller',
-            'xcmdf' => 'chemical/x-cmdf',
-            'xcml' => 'chemical/x-cml',
-            'xcmp' => 'application/vnd.yellowriver-custom-menu',
-            'xcmx' => 'image/x-cmx',
-            'xcom' => 'application/x-msdownload',
-            'xconf' => 'text/plain',
-            'xcpio' => 'application/x-cpio',
-
-            'xcpt' => 'application/mac-compactpro',
-            'xcrd' => 'application/x-mscardfile',
-            'xcrl' => 'application/pkix-crl',
-            'xcrt' => 'application/x-x509-ca-cert',
-            'xcsh' => 'application/x-csh',
-            'xcsml' => 'chemical/x-csml',
-            'xcss' => 'text/css',
-            'xcsv' => 'text/csv',
-            'xcurl' => 'application/vnd.curl',
-
-            'xcww' => 'application/prs.cww',
-            'xdaf' => 'application/vnd.mobius.daf',
-            'xdavmount' => 'application/davmount+xml',
-            'xdd2' => 'application/vnd.oma.dd2+xml',
-            'xddd' => 'application/vnd.fujixerox.ddd',
-            'xdef' => 'text/plain',
-            'xder' => 'application/x-x509-ca-cert',
-            'xdfac' => 'application/vnd.dreamfactory',
-            'xdis' => 'application/vnd.mobius.dis',
-
-            'xdjv' => 'image/vnd.djvu',
-            'xdjvu' => 'image/vnd.djvu',
-            'xdll' => 'application/x-msdownload',
-            'xdna' => 'application/vnd.dna',
-            'xdoc' => 'application/msword',
-            'xdot' => 'application/msword',
-            'xdp' => 'application/vnd.osgi.dp',
-            'xdpg' => 'application/vnd.dpgraph',
-            'xdsc' => 'text/prs.lines.tag',
-
-            'xdtd' => 'application/xml-dtd',
-            'xdvi' => 'application/x-dvi',
-            'xdwf' => 'model/vnd.dwf',
-            'xdwg' => 'image/vnd.dwg',
-            'xdxf' => 'image/vnd.dxf',
-            'xdxp' => 'application/vnd.spotfire.dxp',
-            'xecelp4800' => 'audio/vnd.nuera.ecelp4800',
-            'xecelp7470' => 'audio/vnd.nuera.ecelp7470',
-            'xecelp9600' => 'audio/vnd.nuera.ecelp9600',
-
-            'xecma' => 'application/ecmascript',
-            'xedm' => 'application/vnd.novadigm.edm',
-            'xedx' => 'application/vnd.novadigm.edx',
-            'xefif' => 'application/vnd.picsel',
-            'xei6' => 'application/vnd.pg.osasli',
-            'xeml' => 'message/rfc822',
-            'xeol' => 'audio/vnd.digital-winds',
-            'xeot' => 'application/vnd.ms-fontobject',
-            'xeps' => 'application/postscript',
-
-            'xesf' => 'application/vnd.epson.esf',
-            'xetx' => 'text/x-setext',
-            'xexe' => 'application/x-msdownload',
-            'xext' => 'application/vnd.novadigm.ext',
-            'xez' => 'application/andrew-inset',
-            'xez2' => 'application/vnd.ezpix-album',
-            'xez3' => 'application/vnd.ezpix-package',
-            'xfbs' => 'image/vnd.fastbidsheet',
-            'xfdf' => 'application/vnd.fdf',
-
-            'xfe_launch' => 'application/vnd.denovo.fcselayout-link',
-            'xfg5' => 'application/vnd.fujitsu.oasysgp',
-            'xfli' => 'video/x-fli',
-            'xflo' => 'application/vnd.micrografx.flo',
-            'xflw' => 'application/vnd.kde.kivio',
-            'xflx' => 'text/vnd.fmi.flexstor',
-            'xfly' => 'text/vnd.fly',
-            'xfnc' => 'application/vnd.frogans.fnc',
-            'xfpx' => 'image/vnd.fpx',
-
-            'xfsc' => 'application/vnd.fsc.weblaunch',
-            'xfst' => 'image/vnd.fst',
-            'xftc' => 'application/vnd.fluxtime.clip',
-            'xfti' => 'application/vnd.anser-web-funds-transfer-initiation',
-            'xfvt' => 'video/vnd.fvt',
-            'xfzs' => 'application/vnd.fuzzysheet',
-            'xg3' => 'image/g3fax',
-            'xgac' => 'application/vnd.groove-account',
-            'xgdl' => 'model/vnd.gdl',
-
-            'xghf' => 'application/vnd.groove-help',
-            'xgif' => 'image/gif',
-            'xgim' => 'application/vnd.groove-identity-message',
-            'xgph' => 'application/vnd.flographit',
-            'xgram' => 'application/srgs',
-            'xgrv' => 'application/vnd.groove-injector',
-            'xgrxml' => 'application/srgs+xml',
-            'xgtar' => 'application/x-gtar',
-            'xgtm' => 'application/vnd.groove-tool-message',
-
-            'xgtw' => 'model/vnd.gtw',
-            'xh261' => 'video/h261',
-            'xh263' => 'video/h263',
-            'xh264' => 'video/h264',
-            'xhbci' => 'application/vnd.hbci',
-            'xhdf' => 'application/x-hdf',
-            'xhlp' => 'application/winhlp',
-            'xhpgl' => 'application/vnd.hp-hpgl',
-            'xhpid' => 'application/vnd.hp-hpid',
-
-            'xhps' => 'application/vnd.hp-hps',
-            'xhqx' => 'application/mac-binhex40',
-            'xhtke' => 'application/vnd.kenameaapp',
-            'xhtm' => 'text/html',
-            'xhtml' => 'text/html',
-            'xhvd' => 'application/vnd.yamaha.hv-dic',
-            'xhvp' => 'application/vnd.yamaha.hv-voice',
-            'xhvs' => 'application/vnd.yamaha.hv-script',
-            'xice' => '#x-conference/x-cooltalk',
-
-            'xico' => 'image/x-icon',
-            'xics' => 'text/calendar',
-            'xief' => 'image/ief',
-            'xifb' => 'text/calendar',
-            'xifm' => 'application/vnd.shana.informed.formdata',
-            'xigl' => 'application/vnd.igloader',
-            'xigx' => 'application/vnd.micrografx.igx',
-            'xiif' => 'application/vnd.shana.informed.interchange',
-            'ximp' => 'application/vnd.accpac.simply.imp',
-
-            'xims' => 'application/vnd.ms-ims',
-            'xin' => 'text/plain',
-            'xipk' => 'application/vnd.shana.informed.package',
-            'xirm' => 'application/vnd.ibm.rights-management',
-            'xirp' => 'application/vnd.irepository.package+xml',
-            'xitp' => 'application/vnd.shana.informed.formtemplate',
-            'xivp' => 'application/vnd.immervision-ivp',
-            'xivu' => 'application/vnd.immervision-ivu',
-            'xjad' => 'text/vnd.sun.j2me.app-descriptor',
-
-            'xjam' => 'application/vnd.jam',
-            'xjava' => 'text/x-java-source',
-            'xjisp' => 'application/vnd.jisp',
-            'xjlt' => 'application/vnd.hp-jlyt',
-            'xjoda' => 'application/vnd.joost.joda-archive',
-            'xjpe' => 'image/jpeg',
-            'xjpeg' => 'image/jpeg',
-            'xjpg' => 'image/jpeg',
-            'xjpgm' => 'video/jpm',
-
-            'xjpgv' => 'video/jpeg',
-            'xjpm' => 'video/jpm',
-            'xjs' => 'application/javascript',
-            'xjson' => 'application/json',
-            'xkar' => 'audio/midi',
-            'xkarbon' => 'application/vnd.kde.karbon',
-            'xkfo' => 'application/vnd.kde.kformula',
-            'xkia' => 'application/vnd.kidspiration',
-            'xkml' => 'application/vnd.google-earth.kml+xml',
-
-            'xkmz' => 'application/vnd.google-earth.kmz',
-            'xkon' => 'application/vnd.kde.kontour',
-            'xksp' => 'application/vnd.kde.kspread',
-            'xlatex' => 'application/x-latex',
-            'xlbd' => 'application/vnd.llamagraphics.life-balance.desktop',
-            'xlbe' => 'application/vnd.llamagraphics.life-balance.exchange+xml',
-            'xles' => 'application/vnd.hhe.lesson-player',
-            'xlist' => 'text/plain',
-            'xlog' => 'text/plain',
-
-            'xlrm' => 'application/vnd.ms-lrm',
-            'xltf' => 'application/vnd.frogans.ltf',
-            'xlvp' => 'audio/vnd.lucent.voice',
-            'xlwp' => 'application/vnd.lotus-wordpro',
-            'xm13' => 'application/x-msmediaview',
-            'xm14' => 'application/x-msmediaview',
-            'xm1v' => 'video/mpeg',
-            'xm2a' => 'audio/mpeg',
-            'xm3a' => 'audio/mpeg',
-
-            'xm3u' => 'audio/x-mpegurl',
-            'xm4u' => 'video/vnd.mpegurl',
-            'xmag' => 'application/vnd.ecowin.chart',
-            'xmathml' => 'application/mathml+xml',
-            'xmbk' => 'application/vnd.mobius.mbk',
-            'xmbox' => 'application/mbox',
-            'xmc1' => 'application/vnd.medcalcdata',
-            'xmcd' => 'application/vnd.mcd',
-            'xmdb' => 'application/x-msaccess',
-
-            'xmdi' => 'image/vnd.ms-modi',
-            'xmesh' => 'model/mesh',
-            'xmfm' => 'application/vnd.mfmp',
-            'xmgz' => 'application/vnd.proteus.magazine',
-            'xmid' => 'audio/midi',
-            'xmidi' => 'audio/midi',
-            'xmif' => 'application/vnd.mif',
-            'xmime' => 'message/rfc822',
-            'xmj2' => 'video/mj2',
-
-            'xmjp2' => 'video/mj2',
-            'xmlp' => 'application/vnd.dolby.mlp',
-            'xmmd' => 'application/vnd.chipnuts.karaoke-mmd',
-            'xmmf' => 'application/vnd.smaf',
-            'xmmr' => 'image/vnd.fujixerox.edmics-mmr',
-            'xmny' => 'application/x-msmoney',
-            'xmov' => 'video/quicktime',
-            'xmovie' => 'video/x-sgi-movie',
-            'xmp2' => 'audio/mpeg',
-
-            'xmp2a' => 'audio/mpeg',
-            'xmp3' => 'audio/mpeg',
-            'xmp4' => 'video/mp4',
-            'xmp4a' => 'audio/mp4',
-            'xmp4s' => 'application/mp4',
-            'xmp4v' => 'video/mp4',
-            'xmpc' => 'application/vnd.mophun.certificate',
-            'xmpe' => 'video/mpeg',
-            'xmpeg' => 'video/mpeg',
-
-            'xmpg' => 'video/mpeg',
-            'xmpg4' => 'video/mp4',
-            'xmpga' => 'audio/mpeg',
-            'xmpkg' => 'application/vnd.apple.installer+xml',
-            'xmpm' => 'application/vnd.blueice.multipass',
-            'xmpn' => 'application/vnd.mophun.application',
-            'xmpp' => 'application/vnd.ms-project',
-            'xmpt' => 'application/vnd.ms-project',
-            'xmpy' => 'application/vnd.ibm.minipay',
-
-            'xmqy' => 'application/vnd.mobius.mqy',
-            'xmrc' => 'application/marc',
-            'xmscml' => 'application/mediaservercontrol+xml',
-            'xmseq' => 'application/vnd.mseq',
-            'xmsf' => 'application/vnd.epson.msf',
-            'xmsh' => 'model/mesh',
-            'xmsi' => 'application/x-msdownload',
-            'xmsl' => 'application/vnd.mobius.msl',
-            'xmsty' => 'application/vnd.muvee.style',
-
-            'xmts' => 'model/vnd.mts',
-            'xmus' => 'application/vnd.musician',
-            'xmvb' => 'application/x-msmediaview',
-            'xmwf' => 'application/vnd.mfer',
-            'xmxf' => 'application/mxf',
-            'xmxl' => 'application/vnd.recordare.musicxml',
-            'xmxml' => 'application/xv+xml',
-            'xmxs' => 'application/vnd.triscape.mxs',
-            'xmxu' => 'video/vnd.mpegurl',
-
-            'xn-gage' => 'application/vnd.nokia.n-gage.symbian.install',
-            'xngdat' => 'application/vnd.nokia.n-gage.data',
-            'xnlu' => 'application/vnd.neurolanguage.nlu',
-            'xnml' => 'application/vnd.enliven',
-            'xnnd' => 'application/vnd.noblenet-directory',
-            'xnns' => 'application/vnd.noblenet-sealer',
-            'xnnw' => 'application/vnd.noblenet-web',
-            'xnpx' => 'image/vnd.net-fpx',
-            'xnsf' => 'application/vnd.lotus-notes',
-
-            'xoa2' => 'application/vnd.fujitsu.oasys2',
-            'xoa3' => 'application/vnd.fujitsu.oasys3',
-            'xoas' => 'application/vnd.fujitsu.oasys',
-            'xobd' => 'application/x-msbinder',
-            'xoda' => 'application/oda',
-            'xodc' => 'application/vnd.oasis.opendocument.chart',
-            'xodf' => 'application/vnd.oasis.opendocument.formula',
-            'xodg' => 'application/vnd.oasis.opendocument.graphics',
-            'xodi' => 'application/vnd.oasis.opendocument.image',
-
-            'xodp' => 'application/vnd.oasis.opendocument.presentation',
-            'xods' => 'application/vnd.oasis.opendocument.spreadsheet',
-            'xodt' => 'application/vnd.oasis.opendocument.text',
-            'xogg' => 'application/ogg',
-            'xoprc' => 'application/vnd.palm',
-            'xorg' => 'application/vnd.lotus-organizer',
-            'xotc' => 'application/vnd.oasis.opendocument.chart-template',
-            'xotf' => 'application/vnd.oasis.opendocument.formula-template',
-            'xotg' => 'application/vnd.oasis.opendocument.graphics-template',
-
-            'xoth' => 'application/vnd.oasis.opendocument.text-web',
-            'xoti' => 'application/vnd.oasis.opendocument.image-template',
-            'xotm' => 'application/vnd.oasis.opendocument.text-master',
-            'xots' => 'application/vnd.oasis.opendocument.spreadsheet-template',
-            'xott' => 'application/vnd.oasis.opendocument.text-template',
-            'xoxt' => 'application/vnd.openofficeorg.extension',
-            'xp10' => 'application/pkcs10',
-            'xp7r' => 'application/x-pkcs7-certreqresp',
-            'xp7s' => 'application/pkcs7-signature',
-
-            'xpbd' => 'application/vnd.powerbuilder6',
-            'xpbm' => 'image/x-portable-bitmap',
-            'xpcl' => 'application/vnd.hp-pcl',
-            'xpclxl' => 'application/vnd.hp-pclxl',
-            'xpct' => 'image/x-pict',
-            'xpcx' => 'image/x-pcx',
-            'xpdb' => 'chemical/x-pdb',
-            'xpdf' => 'application/pdf',
-            'xpfr' => 'application/font-tdpfr',
-
-            'xpgm' => 'image/x-portable-graymap',
-            'xpgn' => 'application/x-chess-pgn',
-            'xpgp' => 'application/pgp-encrypted',
-            'xpic' => 'image/x-pict',
-            'xpki' => 'application/pkixcmp',
-            'xpkipath' => 'application/pkix-pkipath',
-            'xplb' => 'application/vnd.3gpp.pic-bw-large',
-            'xplc' => 'application/vnd.mobius.plc',
-            'xplf' => 'application/vnd.pocketlearn',
-
-            'xpls' => 'application/pls+xml',
-            'xpml' => 'application/vnd.ctc-posml',
-            'xpng' => 'image/png',
-            'xpnm' => 'image/x-portable-anymap',
-            'xportpkg' => 'application/vnd.macports.portpkg',
-            'xpot' => 'application/vnd.ms-powerpoint',
-            'xppd' => 'application/vnd.cups-ppd',
-            'xppm' => 'image/x-portable-pixmap',
-            'xpps' => 'application/vnd.ms-powerpoint',
-
-            'xppt' => 'application/vnd.ms-powerpoint',
-            'xpqa' => 'application/vnd.palm',
-            'xprc' => 'application/vnd.palm',
-            'xpre' => 'application/vnd.lotus-freelance',
-            'xprf' => 'application/pics-rules',
-            'xps' => 'application/postscript',
-            'xpsb' => 'application/vnd.3gpp.pic-bw-small',
-            'xpsd' => 'image/vnd.adobe.photoshop',
-            'xptid' => 'application/vnd.pvi.ptid1',
-
-            'xpub' => 'application/x-mspublisher',
-            'xpvb' => 'application/vnd.3gpp.pic-bw-var',
-            'xpwn' => 'application/vnd.3m.post-it-notes',
-            'xqam' => 'application/vnd.epson.quickanime',
-            'xqbo' => 'application/vnd.intu.qbo',
-            'xqfx' => 'application/vnd.intu.qfx',
-            'xqps' => 'application/vnd.publishare-delta-tree',
-            'xqt' => 'video/quicktime',
-            'xra' => 'audio/x-pn-realaudio',
-
-            'xram' => 'audio/x-pn-realaudio',
-            'xrar' => 'application/x-rar-compressed',
-            'xras' => 'image/x-cmu-raster',
-            'xrcprofile' => 'application/vnd.ipunplugged.rcprofile',
-            'xrdf' => 'application/rdf+xml',
-            'xrdz' => 'application/vnd.data-vision.rdz',
-            'xrep' => 'application/vnd.businessobjects',
-            'xrgb' => 'image/x-rgb',
-            'xrif' => 'application/reginfo+xml',
-
-            'xrl' => 'application/resource-lists+xml',
-            'xrlc' => 'image/vnd.fujixerox.edmics-rlc',
-            'xrm' => 'application/vnd.rn-realmedia',
-            'xrmi' => 'audio/midi',
-            'xrmp' => 'audio/x-pn-realaudio-plugin',
-            'xrms' => 'application/vnd.jcp.javame.midlet-rms',
-            'xrnc' => 'application/relax-ng-compact-syntax',
-            'xrpss' => 'application/vnd.nokia.radio-presets',
-            'xrpst' => 'application/vnd.nokia.radio-preset',
-
-            'xrq' => 'application/sparql-query',
-            'xrs' => 'application/rls-services+xml',
-            'xrsd' => 'application/rsd+xml',
-            'xrss' => 'application/rss+xml',
-            'xrtf' => 'application/rtf',
-            'xrtx' => 'text/richtext',
-            'xsaf' => 'application/vnd.yamaha.smaf-audio',
-            'xsbml' => 'application/sbml+xml',
-            'xsc' => 'application/vnd.ibm.secure-container',
-
-            'xscd' => 'application/x-msschedule',
-            'xscm' => 'application/vnd.lotus-screencam',
-            'xscq' => 'application/scvp-cv-request',
-            'xscs' => 'application/scvp-cv-response',
-            'xsdp' => 'application/sdp',
-            'xsee' => 'application/vnd.seemail',
-            'xsema' => 'application/vnd.sema',
-            'xsemd' => 'application/vnd.semd',
-            'xsemf' => 'application/vnd.semf',
-
-            'xsetpay' => 'application/set-payment-initiation',
-            'xsetreg' => 'application/set-registration-initiation',
-            'xsfs' => 'application/vnd.spotfire.sfs',
-            'xsgm' => 'text/sgml',
-            'xsgml' => 'text/sgml',
-            'xsh' => 'application/x-sh',
-            'xshar' => 'application/x-shar',
-            'xshf' => 'application/shf+xml',
-            'xsilo' => 'model/mesh',
-
-            'xsit' => 'application/x-stuffit',
-            'xsitx' => 'application/x-stuffitx',
-            'xslt' => 'application/vnd.epson.salt',
-            'xsnd' => 'audio/basic',
-            'xspf' => 'application/vnd.yamaha.smaf-phrase',
-            'xspl' => 'application/x-futuresplash',
-            'xspot' => 'text/vnd.in3d.spot',
-            'xspp' => 'application/scvp-vp-response',
-            'xspq' => 'application/scvp-vp-request',
-
-            'xsrc' => 'application/x-wais-source',
-            'xsrx' => 'application/sparql-results+xml',
-            'xssf' => 'application/vnd.epson.ssf',
-            'xssml' => 'application/ssml+xml',
-            'xstf' => 'application/vnd.wt.stf',
-            'xstk' => 'application/hyperstudio',
-            'xstr' => 'application/vnd.pg.format',
-            'xsus' => 'application/vnd.sus-calendar',
-            'xsusp' => 'application/vnd.sus-calendar',
-
-            'xsv4cpio' => 'application/x-sv4cpio',
-            'xsv4crc' => 'application/x-sv4crc',
-            'xsvd' => 'application/vnd.svd',
-            'xswf' => 'application/x-shockwave-flash',
-            'xtao' => 'application/vnd.tao.intent-module-archive',
-            'xtar' => 'application/x-tar',
-            'xtcap' => 'application/vnd.3gpp2.tcap',
-            'xtcl' => 'application/x-tcl',
-            'xtex' => 'application/x-tex',
-
-            'xtext' => 'text/plain',
-            'xtif' => 'image/tiff',
-            'xtiff' => 'image/tiff',
-            'xtmo' => 'application/vnd.tmobile-livetv',
-            'xtorrent' => 'application/x-bittorrent',
-            'xtpl' => 'application/vnd.groove-tool-template',
-            'xtpt' => 'application/vnd.trid.tpt',
-            'xtra' => 'application/vnd.trueapp',
-            'xtrm' => 'application/x-msterminal',
-
-            'xtsv' => 'text/tab-separated-values',
-            'xtxd' => 'application/vnd.genomatix.tuxedo',
-            'xtxf' => 'application/vnd.mobius.txf',
-            'xtxt' => 'text/plain',
-            'xumj' => 'application/vnd.umajin',
-            'xunityweb' => 'application/vnd.unity',
-            'xuoml' => 'application/vnd.uoml+xml',
-            'xuri' => 'text/uri-list',
-            'xuris' => 'text/uri-list',
-
-            'xurls' => 'text/uri-list',
-            'xustar' => 'application/x-ustar',
-            'xutz' => 'application/vnd.uiq.theme',
-            'xuu' => 'text/x-uuencode',
-            'xvcd' => 'application/x-cdlink',
-            'xvcf' => 'text/x-vcard',
-            'xvcg' => 'application/vnd.groove-vcard',
-            'xvcs' => 'text/x-vcalendar',
-            'xvcx' => 'application/vnd.vcx',
-
-            'xvis' => 'application/vnd.visionary',
-            'xviv' => 'video/vnd.vivo',
-            'xvrml' => 'model/vrml',
-            'xvsd' => 'application/vnd.visio',
-            'xvsf' => 'application/vnd.vsf',
-            'xvss' => 'application/vnd.visio',
-            'xvst' => 'application/vnd.visio',
-            'xvsw' => 'application/vnd.visio',
-            'xvtu' => 'model/vnd.vtu',
-
-            'xvxml' => 'application/voicexml+xml',
-            'xwav' => 'audio/x-wav',
-            'xwax' => 'audio/x-ms-wax',
-            'xwbmp' => 'image/vnd.wap.wbmp',
-            'xwbs' => 'application/vnd.criticaltools.wbs+xml',
-            'xwbxml' => 'application/vnd.wap.wbxml',
-            'xwcm' => 'application/vnd.ms-works',
-            'xwdb' => 'application/vnd.ms-works',
-            'xwks' => 'application/vnd.ms-works',
-
-            'xwm' => 'video/x-ms-wm',
-            'xwma' => 'audio/x-ms-wma',
-            'xwmd' => 'application/x-ms-wmd',
-            'xwmf' => 'application/x-msmetafile',
-            'xwml' => 'text/vnd.wap.wml',
-            'xwmlc' => 'application/vnd.wap.wmlc',
-            'xwmls' => 'text/vnd.wap.wmlscript',
-            'xwmlsc' => 'application/vnd.wap.wmlscriptc',
-            'xwmv' => 'video/x-ms-wmv',
-
-            'xwmx' => 'video/x-ms-wmx',
-            'xwmz' => 'application/x-ms-wmz',
-            'xwpd' => 'application/vnd.wordperfect',
-            'xwpl' => 'application/vnd.ms-wpl',
-            'xwps' => 'application/vnd.ms-works',
-            'xwqd' => 'application/vnd.wqd',
-            'xwri' => 'application/x-mswrite',
-            'xwrl' => 'model/vrml',
-            'xwsdl' => 'application/wsdl+xml',
-
-            'xwspolicy' => 'application/wspolicy+xml',
-            'xwtb' => 'application/vnd.webturbo',
-            'xwvx' => 'video/x-ms-wvx',
-            'xx3d' => 'application/vnd.hzn-3d-crossword',
-            'xxar' => 'application/vnd.xara',
-            'xxbd' => 'application/vnd.fujixerox.docuworks.binder',
-            'xxbm' => 'image/x-xbitmap',
-            'xxdm' => 'application/vnd.syncml.dm+xml',
-            'xxdp' => 'application/vnd.adobe.xdp+xml',
-
-            'xxdw' => 'application/vnd.fujixerox.docuworks',
-            'xxenc' => 'application/xenc+xml',
-            'xxfdf' => 'application/vnd.adobe.xfdf',
-            'xxfdl' => 'application/vnd.xfdl',
-            'xxht' => 'application/xhtml+xml',
-            'xxhtml' => 'application/xhtml+xml',
-            'xxhvml' => 'application/xv+xml',
-            'xxif' => 'image/vnd.xiff',
-            'xxla' => 'application/vnd.ms-excel',
-
-            'xxlc' => 'application/vnd.ms-excel',
-            'xxlm' => 'application/vnd.ms-excel',
-            'xxls' => 'application/vnd.ms-excel',
-            'xxlt' => 'application/vnd.ms-excel',
-            'xxlw' => 'application/vnd.ms-excel',
-            'xxml' => 'application/xml',
-            'xxo' => 'application/vnd.olpc-sugar',
-            'xxop' => 'application/xop+xml',
-            'xxpm' => 'image/x-xpixmap',
-
-            'xxpr' => 'application/vnd.is-xpr',
-            'xxps' => 'application/vnd.ms-xpsdocument',
-            'xxsl' => 'application/xml',
-            'xxslt' => 'application/xslt+xml',
-            'xxsm' => 'application/vnd.syncml+xml',
-            'xxspf' => 'application/xspf+xml',
-            'xxul' => 'application/vnd.mozilla.xul+xml',
-            'xxvm' => 'application/xv+xml',
-            'xxvml' => 'application/xv+xml',
-
-            'xxwd' => 'image/x-xwindowdump',
-            'xxyz' => 'chemical/x-xyz',
-            'xzaz' => 'application/vnd.zzazz.deck+xml',
-            'xzip' => 'application/zip',
-            'xzmm' => 'application/vnd.handheld-entertainment+xml',
-            'xodt' => 'application/x-vnd.oasis.opendocument.spreadsheet'
-        );
 }
diff --git app/code/core/Mage/Oauth/Model/Server.php app/code/core/Mage/Oauth/Model/Server.php
index 0f233fc..91472b9 100644
--- app/code/core/Mage/Oauth/Model/Server.php
+++ app/code/core/Mage/Oauth/Model/Server.php
@@ -328,10 +328,10 @@ class Mage_Oauth_Model_Server
             if (self::REQUEST_TOKEN == $this->_requestType) {
                 $this->_validateVerifierParam();
 
-                if ($this->_token->getVerifier() != $this->_protocolParams['oauth_verifier']) {
+                if (!hash_equals($this->_token->getVerifier(), $this->_protocolParams['oauth_verifier'])) {
                     $this->_throwException('', self::ERR_VERIFIER_INVALID);
                 }
-                if ($this->_token->getConsumerId() != $this->_consumer->getId()) {
+                if (!hash_equals($this->_token->getConsumerId(), $this->_consumer->getId())) {
                     $this->_throwException('', self::ERR_TOKEN_REJECTED);
                 }
                 if (Mage_Oauth_Model_Token::TYPE_REQUEST != $this->_token->getType()) {
@@ -541,7 +541,7 @@ class Mage_Oauth_Model_Server
             $this->_request->getScheme() . '://' . $this->_request->getHttpHost() . $this->_request->getRequestUri()
         );
 
-        if ($calculatedSign != $this->_protocolParams['oauth_signature']) {
+        if (!hash_equals($calculatedSign, $this->_protocolParams['oauth_signature'])) {
             $this->_throwException($calculatedSign, self::ERR_SIGNATURE_INVALID);
         }
     }
diff --git app/code/core/Mage/Paygate/Model/Authorizenet.php app/code/core/Mage/Paygate/Model/Authorizenet.php
index 37c2441..86e99d4 100644
--- app/code/core/Mage/Paygate/Model/Authorizenet.php
+++ app/code/core/Mage/Paygate/Model/Authorizenet.php
@@ -1261,8 +1261,10 @@ class Mage_Paygate_Model_Authorizenet extends Mage_Payment_Model_Method_Cc
         $uri = $this->getConfigData('cgi_url');
         $client->setUri($uri ? $uri : self::CGI_URL);
         $client->setConfig(array(
-            'maxredirects'=>0,
-            'timeout'=>30,
+            'maxredirects' => 0,
+            'timeout' => 30,
+            'verifyhost' => 2,
+            'verifypeer' => true,
             //'ssltransport' => 'tcp',
         ));
         foreach ($request->getData() as $key => $value) {
@@ -1529,8 +1531,13 @@ class Mage_Paygate_Model_Authorizenet extends Mage_Payment_Model_Method_Cc
 
         $client = new Varien_Http_Client();
         $uri = $this->getConfigData('cgi_url_td');
-        $client->setUri($uri ? $uri : self::CGI_URL_TD);
-        $client->setConfig(array('timeout'=>45));
+        $uri = $uri ? $uri : self::CGI_URL_TD;
+        $client->setUri($uri);
+        $client->setConfig(array(
+            'timeout' => 45,
+            'verifyhost' => 2,
+            'verifypeer' => true,
+        ));
         $client->setHeaders(array('Content-Type: text/xml'));
         $client->setMethod(Zend_Http_Client::POST);
         $client->setRawData($requestBody);
diff --git app/code/core/Mage/Payment/Block/Info/Checkmo.php app/code/core/Mage/Payment/Block/Info/Checkmo.php
index 268605a..5306b52 100644
--- app/code/core/Mage/Payment/Block/Info/Checkmo.php
+++ app/code/core/Mage/Payment/Block/Info/Checkmo.php
@@ -70,7 +70,13 @@ class Mage_Payment_Block_Info_Checkmo extends Mage_Payment_Block_Info
      */
     protected function _convertAdditionalData()
     {
-        $details = @unserialize($this->getInfo()->getAdditionalData());
+        $details = false;
+        try {
+            $details = Mage::helper('core/unserializeArray')
+                ->unserialize($this->getInfo()->getAdditionalData());
+        } catch (Exception $e) {
+            Mage::logException($e);
+        }
         if (is_array($details)) {
             $this->_payableTo = isset($details['payable_to']) ? (string) $details['payable_to'] : '';
             $this->_mailingAddress = isset($details['mailing_address']) ? (string) $details['mailing_address'] : '';
@@ -80,7 +86,7 @@ class Mage_Payment_Block_Info_Checkmo extends Mage_Payment_Block_Info
         }
         return $this;
     }
-    
+
     public function toPdf()
     {
         $this->setTemplate('payment/info/pdf/checkmo.phtml');
diff --git app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php
index 0a76f3c..7e02e92 100644
--- app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php
+++ app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php
@@ -53,6 +53,30 @@ class Mage_Paypal_Model_Resource_Payment_Transaction extends Mage_Core_Model_Res
     }
 
     /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                    ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
+
+    /**
      * Load the transaction object by specified txn_id
      *
      * @param Mage_Paypal_Model_Payment_Transaction $transaction
diff --git app/code/core/Mage/Review/controllers/ProductController.php app/code/core/Mage/Review/controllers/ProductController.php
index 29483e6..6590c79 100644
--- app/code/core/Mage/Review/controllers/ProductController.php
+++ app/code/core/Mage/Review/controllers/ProductController.php
@@ -155,6 +155,12 @@ class Mage_Review_ProductController extends Mage_Core_Controller_Front_Action
      */
     public function postAction()
     {
+        if (!$this->_validateFormKey()) {
+            // returns to the product item page
+            $this->_redirectReferer();
+            return;
+        }
+
         if ($data = Mage::getSingleton('review/session')->getFormData(true)) {
             $rating = array();
             if (isset($data['ratings']) && is_array($data['ratings'])) {
diff --git app/code/core/Mage/Sales/Model/Resource/Order/Payment.php app/code/core/Mage/Sales/Model/Resource/Order/Payment.php
index 3e3572c..2a31cae 100755
--- app/code/core/Mage/Sales/Model/Resource/Order/Payment.php
+++ app/code/core/Mage/Sales/Model/Resource/Order/Payment.php
@@ -58,4 +58,28 @@ class Mage_Sales_Model_Resource_Order_Payment extends Mage_Sales_Model_Resource_
     {
         $this->_init('sales/order_payment', 'entity_id');
     }
+
+    /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
 }
diff --git app/code/core/Mage/Sales/Model/Resource/Order/Payment/Transaction.php app/code/core/Mage/Sales/Model/Resource/Order/Payment/Transaction.php
index 67f0cee..4ea1f37 100755
--- app/code/core/Mage/Sales/Model/Resource/Order/Payment/Transaction.php
+++ app/code/core/Mage/Sales/Model/Resource/Order/Payment/Transaction.php
@@ -53,6 +53,30 @@ class Mage_Sales_Model_Resource_Order_Payment_Transaction extends Mage_Sales_Mod
     }
 
     /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
+
+    /**
      * Update transactions in database using provided transaction as parent for them
      * have to repeat the business logic to avoid accidental injection of wrong transactions
      *
diff --git app/code/core/Mage/Sales/Model/Resource/Quote/Payment.php app/code/core/Mage/Sales/Model/Resource/Quote/Payment.php
index 5fd2bea..a2a8548 100755
--- app/code/core/Mage/Sales/Model/Resource/Quote/Payment.php
+++ app/code/core/Mage/Sales/Model/Resource/Quote/Payment.php
@@ -51,4 +51,28 @@ class Mage_Sales_Model_Resource_Quote_Payment extends Mage_Sales_Model_Resource_
     {
         $this->_init('sales/quote_payment', 'payment_id');
     }
+
+    /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                    ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
 }
diff --git app/code/core/Mage/Sales/Model/Resource/Recurring/Profile.php app/code/core/Mage/Sales/Model/Resource/Recurring/Profile.php
index cd7d1b3..325c911 100755
--- app/code/core/Mage/Sales/Model/Resource/Recurring/Profile.php
+++ app/code/core/Mage/Sales/Model/Resource/Recurring/Profile.php
@@ -54,6 +54,33 @@ class Mage_Sales_Model_Resource_Recurring_Profile extends Mage_Sales_Model_Resou
     }
 
     /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        if ($field != 'additional_info') {
+            return parent::_unserializeField($object, $field, $defaultValue);
+        }
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
+
+    /**
      * Return recurring profile child Orders Ids
      *
      *
diff --git app/code/core/Mage/Uploader/Block/Abstract.php app/code/core/Mage/Uploader/Block/Abstract.php
new file mode 100644
index 0000000..0cba674
--- /dev/null
+++ app/code/core/Mage/Uploader/Block/Abstract.php
@@ -0,0 +1,247 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+abstract class Mage_Uploader_Block_Abstract extends Mage_Adminhtml_Block_Widget
+{
+    /**
+     * Template used for uploader
+     *
+     * @var string
+     */
+    protected $_template = 'media/uploader.phtml';
+
+    /**
+     * @var Mage_Uploader_Model_Config_Misc
+     */
+    protected $_misc;
+
+    /**
+     * @var Mage_Uploader_Model_Config_Uploader
+     */
+    protected $_uploaderConfig;
+
+    /**
+     * @var Mage_Uploader_Model_Config_Browsebutton
+     */
+    protected $_browseButtonConfig;
+
+    /**
+     * @var Mage_Uploader_Model_Config_Misc
+     */
+    protected $_miscConfig;
+
+    /**
+     * @var array
+     */
+    protected $_idsMapping = array();
+
+    /**
+     * Default browse button ID suffix
+     */
+    const DEFAULT_BROWSE_BUTTON_ID_SUFFIX = 'browse';
+
+    /**
+     * Constructor for uploader block
+     *
+     * @see https://github.com/flowjs/flow.js/tree/v2.9.0#configuration
+     * @description Set unique id for block
+     */
+    public function __construct()
+    {
+        parent::__construct();
+        $this->setId($this->getId() . '_Uploader');
+    }
+
+    /**
+     * Helper for file manipulation
+     *
+     * @return Mage_Uploader_Helper_File
+     */
+    protected function _getHelper()
+    {
+        return Mage::helper('uploader/file');
+    }
+
+    /**
+     * @return string
+     */
+    public function getJsonConfig()
+    {
+        return $this->helper('core')->jsonEncode(array(
+            'uploaderConfig'    => $this->getUploaderConfig()->getData(),
+            'elementIds'        => $this->_getElementIdsMapping(),
+            'browseConfig'      => $this->getButtonConfig()->getData(),
+            'miscConfig'        => $this->getMiscConfig()->getData(),
+        ));
+    }
+
+    /**
+     * Get mapping of ids for front-end use
+     *
+     * @return array
+     */
+    protected function _getElementIdsMapping()
+    {
+        return $this->_idsMapping;
+    }
+
+    /**
+     * Add mapping ids for front-end use
+     *
+     * @param array $additionalButtons
+     * @return $this
+     */
+    protected function _addElementIdsMapping($additionalButtons = array())
+    {
+        $this->_idsMapping = array_merge($this->_idsMapping, $additionalButtons);
+
+        return $this;
+    }
+
+    /**
+     * Prepare layout, create buttons, set front-end elements ids
+     *
+     * @return Mage_Core_Block_Abstract
+     */
+    protected function _prepareLayout()
+    {
+        $this->setChild(
+            'browse_button',
+            $this->getLayout()->createBlock('adminhtml/widget_button')
+                ->addData(array(
+                    // Workaround for IE9
+                    'before_html'   => sprintf(
+                        '<div style="display:inline-block;" id="%s">',
+                        $this->getElementId(self::DEFAULT_BROWSE_BUTTON_ID_SUFFIX)
+                    ),
+                    'after_html'    => '</div>',
+                    'id'            => $this->getElementId(self::DEFAULT_BROWSE_BUTTON_ID_SUFFIX . '_button'),
+                    'label'         => Mage::helper('uploader')->__('Browse Files...'),
+                    'type'          => 'button',
+                ))
+        );
+
+        $this->setChild(
+            'delete_button',
+            $this->getLayout()->createBlock('adminhtml/widget_button')
+                ->addData(array(
+                    'id'      => '{{id}}',
+                    'class'   => 'delete',
+                    'type'    => 'button',
+                    'label'   => Mage::helper('uploader')->__('Remove')
+                ))
+        );
+
+        $this->_addElementIdsMapping(array(
+            'container'         => $this->getHtmlId(),
+            'templateFile'      => $this->getElementId('template'),
+            'browse'            => $this->_prepareElementsIds(array(self::DEFAULT_BROWSE_BUTTON_ID_SUFFIX))
+        ));
+
+        return parent::_prepareLayout();
+    }
+
+    /**
+     * Get browse button html
+     *
+     * @return string
+     */
+    public function getBrowseButtonHtml()
+    {
+        return $this->getChildHtml('browse_button');
+    }
+
+    /**
+     * Get delete button html
+     *
+     * @return string
+     */
+    public function getDeleteButtonHtml()
+    {
+        return $this->getChildHtml('delete_button');
+    }
+
+    /**
+     * Get uploader misc settings
+     *
+     * @return Mage_Uploader_Model_Config_Misc
+     */
+    public function getMiscConfig()
+    {
+        if (is_null($this->_miscConfig)) {
+            $this->_miscConfig = Mage::getModel('uploader/config_misc');
+        }
+        return $this->_miscConfig;
+    }
+
+    /**
+     * Get uploader general settings
+     *
+     * @return Mage_Uploader_Model_Config_Uploader
+     */
+    public function getUploaderConfig()
+    {
+        if (is_null($this->_uploaderConfig)) {
+            $this->_uploaderConfig = Mage::getModel('uploader/config_uploader');
+        }
+        return $this->_uploaderConfig;
+    }
+
+    /**
+     * Get browse button settings
+     *
+     * @return Mage_Uploader_Model_Config_Browsebutton
+     */
+    public function getButtonConfig()
+    {
+        if (is_null($this->_browseButtonConfig)) {
+            $this->_browseButtonConfig = Mage::getModel('uploader/config_browsebutton');
+        }
+        return $this->_browseButtonConfig;
+    }
+
+    /**
+     * Get button unique id
+     *
+     * @param string $suffix
+     * @return string
+     */
+    public function getElementId($suffix)
+    {
+        return $this->getHtmlId() . '-' . $suffix;
+    }
+
+    /**
+     * Prepare actual elements ids from suffixes
+     *
+     * @param array $targets $type => array($idsSuffixes)
+     * @return array $type => array($htmlIds)
+     */
+    protected function _prepareElementsIds($targets)
+    {
+        return array_map(array($this, 'getElementId'), array_unique(array_values($targets)));
+    }
+}
diff --git app/code/core/Mage/Uploader/Block/Multiple.php app/code/core/Mage/Uploader/Block/Multiple.php
new file mode 100644
index 0000000..923f045
--- /dev/null
+++ app/code/core/Mage/Uploader/Block/Multiple.php
@@ -0,0 +1,71 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+class Mage_Uploader_Block_Multiple extends Mage_Uploader_Block_Abstract
+{
+    /**
+     *
+     * Default upload button ID suffix
+     */
+    const DEFAULT_UPLOAD_BUTTON_ID_SUFFIX = 'upload';
+
+
+    /**
+     * Prepare layout, create upload button
+     *
+     * @return Mage_Uploader_Block_Multiple
+     */
+    protected function _prepareLayout()
+    {
+        parent::_prepareLayout();
+
+        $this->setChild(
+            'upload_button',
+            $this->getLayout()->createBlock('adminhtml/widget_button')
+                ->addData(array(
+                    'id'      => $this->getElementId(self::DEFAULT_UPLOAD_BUTTON_ID_SUFFIX),
+                    'label'   => Mage::helper('uploader')->__('Upload Files'),
+                    'type'    => 'button',
+                ))
+        );
+
+        $this->_addElementIdsMapping(array(
+            'upload' => $this->_prepareElementsIds(array(self::DEFAULT_UPLOAD_BUTTON_ID_SUFFIX))
+        ));
+
+        return $this;
+    }
+
+    /**
+     * Get upload button html
+     *
+     * @return string
+     */
+    public function getUploadButtonHtml()
+    {
+        return $this->getChildHtml('upload_button');
+    }
+}
diff --git app/code/core/Mage/Uploader/Block/Single.php app/code/core/Mage/Uploader/Block/Single.php
new file mode 100644
index 0000000..4ce4663
--- /dev/null
+++ app/code/core/Mage/Uploader/Block/Single.php
@@ -0,0 +1,52 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+class Mage_Uploader_Block_Single extends Mage_Uploader_Block_Abstract
+{
+    /**
+     * Prepare layout, change button and set front-end element ids mapping
+     *
+     * @return Mage_Core_Block_Abstract
+     */
+    protected function _prepareLayout()
+    {
+        parent::_prepareLayout();
+        $this->getChild('browse_button')->setLabel(Mage::helper('uploader')->__('...'));
+
+        return $this;
+    }
+
+    /**
+     * Constructor for single uploader block
+     */
+    public function __construct()
+    {
+        parent::__construct();
+
+        $this->getUploaderConfig()->setSingleFile(true);
+        $this->getButtonConfig()->setSingleFile(true);
+    }
+}
diff --git app/code/core/Mage/Uploader/Helper/Data.php app/code/core/Mage/Uploader/Helper/Data.php
new file mode 100644
index 0000000..c260604
--- /dev/null
+++ app/code/core/Mage/Uploader/Helper/Data.php
@@ -0,0 +1,30 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+class Mage_Uploader_Helper_Data extends Mage_Core_Helper_Abstract
+{
+
+}
diff --git app/code/core/Mage/Uploader/Helper/File.php app/code/core/Mage/Uploader/Helper/File.php
new file mode 100644
index 0000000..9685a03
--- /dev/null
+++ app/code/core/Mage/Uploader/Helper/File.php
@@ -0,0 +1,750 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+class Mage_Uploader_Helper_File extends Mage_Core_Helper_Abstract
+{
+    /**
+     * List of pre-defined MIME types
+     *
+     * @var array
+     */
+    protected $_mimeTypes =
+        array(
+            'x123' => 'application/vnd.lotus-1-2-3',
+            'x3dml' => 'text/vnd.in3d.3dml',
+            'x3g2' => 'video/3gpp2',
+            'x3gp' => 'video/3gpp',
+            'xace' => 'application/x-ace-compressed',
+            'xacu' => 'application/vnd.acucobol',
+            'xaep' => 'application/vnd.audiograph',
+            'xai' => 'application/postscript',
+            'xaif' => 'audio/x-aiff',
+
+            'xaifc' => 'audio/x-aiff',
+            'xaiff' => 'audio/x-aiff',
+            'xami' => 'application/vnd.amiga.ami',
+            'xapr' => 'application/vnd.lotus-approach',
+            'xasf' => 'video/x-ms-asf',
+            'xaso' => 'application/vnd.accpac.simply.aso',
+            'xasx' => 'video/x-ms-asf',
+            'xatom' => 'application/atom+xml',
+            'xatomcat' => 'application/atomcat+xml',
+
+            'xatomsvc' => 'application/atomsvc+xml',
+            'xatx' => 'application/vnd.antix.game-component',
+            'xau' => 'audio/basic',
+            'xavi' => 'video/x-msvideo',
+            'xbat' => 'application/x-msdownload',
+            'xbcpio' => 'application/x-bcpio',
+            'xbdm' => 'application/vnd.syncml.dm+wbxml',
+            'xbh2' => 'application/vnd.fujitsu.oasysprs',
+            'xbmi' => 'application/vnd.bmi',
+
+            'xbmp' => 'image/bmp',
+            'xbox' => 'application/vnd.previewsystems.box',
+            'xboz' => 'application/x-bzip2',
+            'xbtif' => 'image/prs.btif',
+            'xbz' => 'application/x-bzip',
+            'xbz2' => 'application/x-bzip2',
+            'xcab' => 'application/vnd.ms-cab-compressed',
+            'xccxml' => 'application/ccxml+xml',
+            'xcdbcmsg' => 'application/vnd.contact.cmsg',
+
+            'xcdkey' => 'application/vnd.mediastation.cdkey',
+            'xcdx' => 'chemical/x-cdx',
+            'xcdxml' => 'application/vnd.chemdraw+xml',
+            'xcdy' => 'application/vnd.cinderella',
+            'xcer' => 'application/pkix-cert',
+            'xcgm' => 'image/cgm',
+            'xchat' => 'application/x-chat',
+            'xchm' => 'application/vnd.ms-htmlhelp',
+            'xchrt' => 'application/vnd.kde.kchart',
+
+            'xcif' => 'chemical/x-cif',
+            'xcii' => 'application/vnd.anser-web-certificate-issue-initiation',
+            'xcil' => 'application/vnd.ms-artgalry',
+            'xcla' => 'application/vnd.claymore',
+            'xclkk' => 'application/vnd.crick.clicker.keyboard',
+            'xclkp' => 'application/vnd.crick.clicker.palette',
+            'xclkt' => 'application/vnd.crick.clicker.template',
+            'xclkw' => 'application/vnd.crick.clicker.wordbank',
+            'xclkx' => 'application/vnd.crick.clicker',
+
+            'xclp' => 'application/x-msclip',
+            'xcmc' => 'application/vnd.cosmocaller',
+            'xcmdf' => 'chemical/x-cmdf',
+            'xcml' => 'chemical/x-cml',
+            'xcmp' => 'application/vnd.yellowriver-custom-menu',
+            'xcmx' => 'image/x-cmx',
+            'xcom' => 'application/x-msdownload',
+            'xconf' => 'text/plain',
+            'xcpio' => 'application/x-cpio',
+
+            'xcpt' => 'application/mac-compactpro',
+            'xcrd' => 'application/x-mscardfile',
+            'xcrl' => 'application/pkix-crl',
+            'xcrt' => 'application/x-x509-ca-cert',
+            'xcsh' => 'application/x-csh',
+            'xcsml' => 'chemical/x-csml',
+            'xcss' => 'text/css',
+            'xcsv' => 'text/csv',
+            'xcurl' => 'application/vnd.curl',
+
+            'xcww' => 'application/prs.cww',
+            'xdaf' => 'application/vnd.mobius.daf',
+            'xdavmount' => 'application/davmount+xml',
+            'xdd2' => 'application/vnd.oma.dd2+xml',
+            'xddd' => 'application/vnd.fujixerox.ddd',
+            'xdef' => 'text/plain',
+            'xder' => 'application/x-x509-ca-cert',
+            'xdfac' => 'application/vnd.dreamfactory',
+            'xdis' => 'application/vnd.mobius.dis',
+
+            'xdjv' => 'image/vnd.djvu',
+            'xdjvu' => 'image/vnd.djvu',
+            'xdll' => 'application/x-msdownload',
+            'xdna' => 'application/vnd.dna',
+            'xdoc' => 'application/msword',
+            'xdot' => 'application/msword',
+            'xdp' => 'application/vnd.osgi.dp',
+            'xdpg' => 'application/vnd.dpgraph',
+            'xdsc' => 'text/prs.lines.tag',
+
+            'xdtd' => 'application/xml-dtd',
+            'xdvi' => 'application/x-dvi',
+            'xdwf' => 'model/vnd.dwf',
+            'xdwg' => 'image/vnd.dwg',
+            'xdxf' => 'image/vnd.dxf',
+            'xdxp' => 'application/vnd.spotfire.dxp',
+            'xecelp4800' => 'audio/vnd.nuera.ecelp4800',
+            'xecelp7470' => 'audio/vnd.nuera.ecelp7470',
+            'xecelp9600' => 'audio/vnd.nuera.ecelp9600',
+
+            'xecma' => 'application/ecmascript',
+            'xedm' => 'application/vnd.novadigm.edm',
+            'xedx' => 'application/vnd.novadigm.edx',
+            'xefif' => 'application/vnd.picsel',
+            'xei6' => 'application/vnd.pg.osasli',
+            'xeml' => 'message/rfc822',
+            'xeol' => 'audio/vnd.digital-winds',
+            'xeot' => 'application/vnd.ms-fontobject',
+            'xeps' => 'application/postscript',
+
+            'xesf' => 'application/vnd.epson.esf',
+            'xetx' => 'text/x-setext',
+            'xexe' => 'application/x-msdownload',
+            'xext' => 'application/vnd.novadigm.ext',
+            'xez' => 'application/andrew-inset',
+            'xez2' => 'application/vnd.ezpix-album',
+            'xez3' => 'application/vnd.ezpix-package',
+            'xfbs' => 'image/vnd.fastbidsheet',
+            'xfdf' => 'application/vnd.fdf',
+
+            'xfe_launch' => 'application/vnd.denovo.fcselayout-link',
+            'xfg5' => 'application/vnd.fujitsu.oasysgp',
+            'xfli' => 'video/x-fli',
+            'xflo' => 'application/vnd.micrografx.flo',
+            'xflw' => 'application/vnd.kde.kivio',
+            'xflx' => 'text/vnd.fmi.flexstor',
+            'xfly' => 'text/vnd.fly',
+            'xfnc' => 'application/vnd.frogans.fnc',
+            'xfpx' => 'image/vnd.fpx',
+
+            'xfsc' => 'application/vnd.fsc.weblaunch',
+            'xfst' => 'image/vnd.fst',
+            'xftc' => 'application/vnd.fluxtime.clip',
+            'xfti' => 'application/vnd.anser-web-funds-transfer-initiation',
+            'xfvt' => 'video/vnd.fvt',
+            'xfzs' => 'application/vnd.fuzzysheet',
+            'xg3' => 'image/g3fax',
+            'xgac' => 'application/vnd.groove-account',
+            'xgdl' => 'model/vnd.gdl',
+
+            'xghf' => 'application/vnd.groove-help',
+            'xgif' => 'image/gif',
+            'xgim' => 'application/vnd.groove-identity-message',
+            'xgph' => 'application/vnd.flographit',
+            'xgram' => 'application/srgs',
+            'xgrv' => 'application/vnd.groove-injector',
+            'xgrxml' => 'application/srgs+xml',
+            'xgtar' => 'application/x-gtar',
+            'xgtm' => 'application/vnd.groove-tool-message',
+
+            'xsvg' => 'image/svg+xml',
+
+            'xgtw' => 'model/vnd.gtw',
+            'xh261' => 'video/h261',
+            'xh263' => 'video/h263',
+            'xh264' => 'video/h264',
+            'xhbci' => 'application/vnd.hbci',
+            'xhdf' => 'application/x-hdf',
+            'xhlp' => 'application/winhlp',
+            'xhpgl' => 'application/vnd.hp-hpgl',
+            'xhpid' => 'application/vnd.hp-hpid',
+
+            'xhps' => 'application/vnd.hp-hps',
+            'xhqx' => 'application/mac-binhex40',
+            'xhtke' => 'application/vnd.kenameaapp',
+            'xhtm' => 'text/html',
+            'xhtml' => 'text/html',
+            'xhvd' => 'application/vnd.yamaha.hv-dic',
+            'xhvp' => 'application/vnd.yamaha.hv-voice',
+            'xhvs' => 'application/vnd.yamaha.hv-script',
+            'xice' => '#x-conference/x-cooltalk',
+
+            'xico' => 'image/x-icon',
+            'xics' => 'text/calendar',
+            'xief' => 'image/ief',
+            'xifb' => 'text/calendar',
+            'xifm' => 'application/vnd.shana.informed.formdata',
+            'xigl' => 'application/vnd.igloader',
+            'xigx' => 'application/vnd.micrografx.igx',
+            'xiif' => 'application/vnd.shana.informed.interchange',
+            'ximp' => 'application/vnd.accpac.simply.imp',
+
+            'xims' => 'application/vnd.ms-ims',
+            'xin' => 'text/plain',
+            'xipk' => 'application/vnd.shana.informed.package',
+            'xirm' => 'application/vnd.ibm.rights-management',
+            'xirp' => 'application/vnd.irepository.package+xml',
+            'xitp' => 'application/vnd.shana.informed.formtemplate',
+            'xivp' => 'application/vnd.immervision-ivp',
+            'xivu' => 'application/vnd.immervision-ivu',
+            'xjad' => 'text/vnd.sun.j2me.app-descriptor',
+
+            'xjam' => 'application/vnd.jam',
+            'xjava' => 'text/x-java-source',
+            'xjisp' => 'application/vnd.jisp',
+            'xjlt' => 'application/vnd.hp-jlyt',
+            'xjoda' => 'application/vnd.joost.joda-archive',
+            'xjpe' => 'image/jpeg',
+            'xjpeg' => 'image/jpeg',
+            'xjpg' => 'image/jpeg',
+            'xjpgm' => 'video/jpm',
+
+            'xjpgv' => 'video/jpeg',
+            'xjpm' => 'video/jpm',
+            'xjs' => 'application/javascript',
+            'xjson' => 'application/json',
+            'xkar' => 'audio/midi',
+            'xkarbon' => 'application/vnd.kde.karbon',
+            'xkfo' => 'application/vnd.kde.kformula',
+            'xkia' => 'application/vnd.kidspiration',
+            'xkml' => 'application/vnd.google-earth.kml+xml',
+
+            'xkmz' => 'application/vnd.google-earth.kmz',
+            'xkon' => 'application/vnd.kde.kontour',
+            'xksp' => 'application/vnd.kde.kspread',
+            'xlatex' => 'application/x-latex',
+            'xlbd' => 'application/vnd.llamagraphics.life-balance.desktop',
+            'xlbe' => 'application/vnd.llamagraphics.life-balance.exchange+xml',
+            'xles' => 'application/vnd.hhe.lesson-player',
+            'xlist' => 'text/plain',
+            'xlog' => 'text/plain',
+
+            'xlrm' => 'application/vnd.ms-lrm',
+            'xltf' => 'application/vnd.frogans.ltf',
+            'xlvp' => 'audio/vnd.lucent.voice',
+            'xlwp' => 'application/vnd.lotus-wordpro',
+            'xm13' => 'application/x-msmediaview',
+            'xm14' => 'application/x-msmediaview',
+            'xm1v' => 'video/mpeg',
+            'xm2a' => 'audio/mpeg',
+            'xm3a' => 'audio/mpeg',
+
+            'xm3u' => 'audio/x-mpegurl',
+            'xm4u' => 'video/vnd.mpegurl',
+            'xmag' => 'application/vnd.ecowin.chart',
+            'xmathml' => 'application/mathml+xml',
+            'xmbk' => 'application/vnd.mobius.mbk',
+            'xmbox' => 'application/mbox',
+            'xmc1' => 'application/vnd.medcalcdata',
+            'xmcd' => 'application/vnd.mcd',
+            'xmdb' => 'application/x-msaccess',
+
+            'xmdi' => 'image/vnd.ms-modi',
+            'xmesh' => 'model/mesh',
+            'xmfm' => 'application/vnd.mfmp',
+            'xmgz' => 'application/vnd.proteus.magazine',
+            'xmid' => 'audio/midi',
+            'xmidi' => 'audio/midi',
+            'xmif' => 'application/vnd.mif',
+            'xmime' => 'message/rfc822',
+            'xmj2' => 'video/mj2',
+
+            'xmjp2' => 'video/mj2',
+            'xmlp' => 'application/vnd.dolby.mlp',
+            'xmmd' => 'application/vnd.chipnuts.karaoke-mmd',
+            'xmmf' => 'application/vnd.smaf',
+            'xmmr' => 'image/vnd.fujixerox.edmics-mmr',
+            'xmny' => 'application/x-msmoney',
+            'xmov' => 'video/quicktime',
+            'xmovie' => 'video/x-sgi-movie',
+            'xmp2' => 'audio/mpeg',
+
+            'xmp2a' => 'audio/mpeg',
+            'xmp3' => 'audio/mpeg',
+            'xmp4' => 'video/mp4',
+            'xmp4a' => 'audio/mp4',
+            'xmp4s' => 'application/mp4',
+            'xmp4v' => 'video/mp4',
+            'xmpc' => 'application/vnd.mophun.certificate',
+            'xmpe' => 'video/mpeg',
+            'xmpeg' => 'video/mpeg',
+
+            'xmpg' => 'video/mpeg',
+            'xmpg4' => 'video/mp4',
+            'xmpga' => 'audio/mpeg',
+            'xmpkg' => 'application/vnd.apple.installer+xml',
+            'xmpm' => 'application/vnd.blueice.multipass',
+            'xmpn' => 'application/vnd.mophun.application',
+            'xmpp' => 'application/vnd.ms-project',
+            'xmpt' => 'application/vnd.ms-project',
+            'xmpy' => 'application/vnd.ibm.minipay',
+
+            'xmqy' => 'application/vnd.mobius.mqy',
+            'xmrc' => 'application/marc',
+            'xmscml' => 'application/mediaservercontrol+xml',
+            'xmseq' => 'application/vnd.mseq',
+            'xmsf' => 'application/vnd.epson.msf',
+            'xmsh' => 'model/mesh',
+            'xmsi' => 'application/x-msdownload',
+            'xmsl' => 'application/vnd.mobius.msl',
+            'xmsty' => 'application/vnd.muvee.style',
+
+            'xmts' => 'model/vnd.mts',
+            'xmus' => 'application/vnd.musician',
+            'xmvb' => 'application/x-msmediaview',
+            'xmwf' => 'application/vnd.mfer',
+            'xmxf' => 'application/mxf',
+            'xmxl' => 'application/vnd.recordare.musicxml',
+            'xmxml' => 'application/xv+xml',
+            'xmxs' => 'application/vnd.triscape.mxs',
+            'xmxu' => 'video/vnd.mpegurl',
+
+            'xn-gage' => 'application/vnd.nokia.n-gage.symbian.install',
+            'xngdat' => 'application/vnd.nokia.n-gage.data',
+            'xnlu' => 'application/vnd.neurolanguage.nlu',
+            'xnml' => 'application/vnd.enliven',
+            'xnnd' => 'application/vnd.noblenet-directory',
+            'xnns' => 'application/vnd.noblenet-sealer',
+            'xnnw' => 'application/vnd.noblenet-web',
+            'xnpx' => 'image/vnd.net-fpx',
+            'xnsf' => 'application/vnd.lotus-notes',
+
+            'xoa2' => 'application/vnd.fujitsu.oasys2',
+            'xoa3' => 'application/vnd.fujitsu.oasys3',
+            'xoas' => 'application/vnd.fujitsu.oasys',
+            'xobd' => 'application/x-msbinder',
+            'xoda' => 'application/oda',
+            'xodc' => 'application/vnd.oasis.opendocument.chart',
+            'xodf' => 'application/vnd.oasis.opendocument.formula',
+            'xodg' => 'application/vnd.oasis.opendocument.graphics',
+            'xodi' => 'application/vnd.oasis.opendocument.image',
+
+            'xodp' => 'application/vnd.oasis.opendocument.presentation',
+            'xods' => 'application/vnd.oasis.opendocument.spreadsheet',
+            'xodt' => 'application/vnd.oasis.opendocument.text',
+            'xogg' => 'application/ogg',
+            'xoprc' => 'application/vnd.palm',
+            'xorg' => 'application/vnd.lotus-organizer',
+            'xotc' => 'application/vnd.oasis.opendocument.chart-template',
+            'xotf' => 'application/vnd.oasis.opendocument.formula-template',
+            'xotg' => 'application/vnd.oasis.opendocument.graphics-template',
+
+            'xoth' => 'application/vnd.oasis.opendocument.text-web',
+            'xoti' => 'application/vnd.oasis.opendocument.image-template',
+            'xotm' => 'application/vnd.oasis.opendocument.text-master',
+            'xots' => 'application/vnd.oasis.opendocument.spreadsheet-template',
+            'xott' => 'application/vnd.oasis.opendocument.text-template',
+            'xoxt' => 'application/vnd.openofficeorg.extension',
+            'xp10' => 'application/pkcs10',
+            'xp7r' => 'application/x-pkcs7-certreqresp',
+            'xp7s' => 'application/pkcs7-signature',
+
+            'xpbd' => 'application/vnd.powerbuilder6',
+            'xpbm' => 'image/x-portable-bitmap',
+            'xpcl' => 'application/vnd.hp-pcl',
+            'xpclxl' => 'application/vnd.hp-pclxl',
+            'xpct' => 'image/x-pict',
+            'xpcx' => 'image/x-pcx',
+            'xpdb' => 'chemical/x-pdb',
+            'xpdf' => 'application/pdf',
+            'xpfr' => 'application/font-tdpfr',
+
+            'xpgm' => 'image/x-portable-graymap',
+            'xpgn' => 'application/x-chess-pgn',
+            'xpgp' => 'application/pgp-encrypted',
+            'xpic' => 'image/x-pict',
+            'xpki' => 'application/pkixcmp',
+            'xpkipath' => 'application/pkix-pkipath',
+            'xplb' => 'application/vnd.3gpp.pic-bw-large',
+            'xplc' => 'application/vnd.mobius.plc',
+            'xplf' => 'application/vnd.pocketlearn',
+
+            'xpls' => 'application/pls+xml',
+            'xpml' => 'application/vnd.ctc-posml',
+            'xpng' => 'image/png',
+            'xpnm' => 'image/x-portable-anymap',
+            'xportpkg' => 'application/vnd.macports.portpkg',
+            'xpot' => 'application/vnd.ms-powerpoint',
+            'xppd' => 'application/vnd.cups-ppd',
+            'xppm' => 'image/x-portable-pixmap',
+            'xpps' => 'application/vnd.ms-powerpoint',
+
+            'xppt' => 'application/vnd.ms-powerpoint',
+            'xpqa' => 'application/vnd.palm',
+            'xprc' => 'application/vnd.palm',
+            'xpre' => 'application/vnd.lotus-freelance',
+            'xprf' => 'application/pics-rules',
+            'xps' => 'application/postscript',
+            'xpsb' => 'application/vnd.3gpp.pic-bw-small',
+            'xpsd' => 'image/vnd.adobe.photoshop',
+            'xptid' => 'application/vnd.pvi.ptid1',
+
+            'xpub' => 'application/x-mspublisher',
+            'xpvb' => 'application/vnd.3gpp.pic-bw-var',
+            'xpwn' => 'application/vnd.3m.post-it-notes',
+            'xqam' => 'application/vnd.epson.quickanime',
+            'xqbo' => 'application/vnd.intu.qbo',
+            'xqfx' => 'application/vnd.intu.qfx',
+            'xqps' => 'application/vnd.publishare-delta-tree',
+            'xqt' => 'video/quicktime',
+            'xra' => 'audio/x-pn-realaudio',
+
+            'xram' => 'audio/x-pn-realaudio',
+            'xrar' => 'application/x-rar-compressed',
+            'xras' => 'image/x-cmu-raster',
+            'xrcprofile' => 'application/vnd.ipunplugged.rcprofile',
+            'xrdf' => 'application/rdf+xml',
+            'xrdz' => 'application/vnd.data-vision.rdz',
+            'xrep' => 'application/vnd.businessobjects',
+            'xrgb' => 'image/x-rgb',
+            'xrif' => 'application/reginfo+xml',
+
+            'xrl' => 'application/resource-lists+xml',
+            'xrlc' => 'image/vnd.fujixerox.edmics-rlc',
+            'xrm' => 'application/vnd.rn-realmedia',
+            'xrmi' => 'audio/midi',
+            'xrmp' => 'audio/x-pn-realaudio-plugin',
+            'xrms' => 'application/vnd.jcp.javame.midlet-rms',
+            'xrnc' => 'application/relax-ng-compact-syntax',
+            'xrpss' => 'application/vnd.nokia.radio-presets',
+            'xrpst' => 'application/vnd.nokia.radio-preset',
+
+            'xrq' => 'application/sparql-query',
+            'xrs' => 'application/rls-services+xml',
+            'xrsd' => 'application/rsd+xml',
+            'xrss' => 'application/rss+xml',
+            'xrtf' => 'application/rtf',
+            'xrtx' => 'text/richtext',
+            'xsaf' => 'application/vnd.yamaha.smaf-audio',
+            'xsbml' => 'application/sbml+xml',
+            'xsc' => 'application/vnd.ibm.secure-container',
+
+            'xscd' => 'application/x-msschedule',
+            'xscm' => 'application/vnd.lotus-screencam',
+            'xscq' => 'application/scvp-cv-request',
+            'xscs' => 'application/scvp-cv-response',
+            'xsdp' => 'application/sdp',
+            'xsee' => 'application/vnd.seemail',
+            'xsema' => 'application/vnd.sema',
+            'xsemd' => 'application/vnd.semd',
+            'xsemf' => 'application/vnd.semf',
+
+            'xsetpay' => 'application/set-payment-initiation',
+            'xsetreg' => 'application/set-registration-initiation',
+            'xsfs' => 'application/vnd.spotfire.sfs',
+            'xsgm' => 'text/sgml',
+            'xsgml' => 'text/sgml',
+            'xsh' => 'application/x-sh',
+            'xshar' => 'application/x-shar',
+            'xshf' => 'application/shf+xml',
+            'xsilo' => 'model/mesh',
+
+            'xsit' => 'application/x-stuffit',
+            'xsitx' => 'application/x-stuffitx',
+            'xslt' => 'application/vnd.epson.salt',
+            'xsnd' => 'audio/basic',
+            'xspf' => 'application/vnd.yamaha.smaf-phrase',
+            'xspl' => 'application/x-futuresplash',
+            'xspot' => 'text/vnd.in3d.spot',
+            'xspp' => 'application/scvp-vp-response',
+            'xspq' => 'application/scvp-vp-request',
+
+            'xsrc' => 'application/x-wais-source',
+            'xsrx' => 'application/sparql-results+xml',
+            'xssf' => 'application/vnd.epson.ssf',
+            'xssml' => 'application/ssml+xml',
+            'xstf' => 'application/vnd.wt.stf',
+            'xstk' => 'application/hyperstudio',
+            'xstr' => 'application/vnd.pg.format',
+            'xsus' => 'application/vnd.sus-calendar',
+            'xsusp' => 'application/vnd.sus-calendar',
+
+            'xsv4cpio' => 'application/x-sv4cpio',
+            'xsv4crc' => 'application/x-sv4crc',
+            'xsvd' => 'application/vnd.svd',
+            'xswf' => 'application/x-shockwave-flash',
+            'xtao' => 'application/vnd.tao.intent-module-archive',
+            'xtar' => 'application/x-tar',
+            'xtcap' => 'application/vnd.3gpp2.tcap',
+            'xtcl' => 'application/x-tcl',
+            'xtex' => 'application/x-tex',
+
+            'xtext' => 'text/plain',
+            'xtif' => 'image/tiff',
+            'xtiff' => 'image/tiff',
+            'xtmo' => 'application/vnd.tmobile-livetv',
+            'xtorrent' => 'application/x-bittorrent',
+            'xtpl' => 'application/vnd.groove-tool-template',
+            'xtpt' => 'application/vnd.trid.tpt',
+            'xtra' => 'application/vnd.trueapp',
+            'xtrm' => 'application/x-msterminal',
+
+            'xtsv' => 'text/tab-separated-values',
+            'xtxd' => 'application/vnd.genomatix.tuxedo',
+            'xtxf' => 'application/vnd.mobius.txf',
+            'xtxt' => 'text/plain',
+            'xumj' => 'application/vnd.umajin',
+            'xunityweb' => 'application/vnd.unity',
+            'xuoml' => 'application/vnd.uoml+xml',
+            'xuri' => 'text/uri-list',
+            'xuris' => 'text/uri-list',
+
+            'xurls' => 'text/uri-list',
+            'xustar' => 'application/x-ustar',
+            'xutz' => 'application/vnd.uiq.theme',
+            'xuu' => 'text/x-uuencode',
+            'xvcd' => 'application/x-cdlink',
+            'xvcf' => 'text/x-vcard',
+            'xvcg' => 'application/vnd.groove-vcard',
+            'xvcs' => 'text/x-vcalendar',
+            'xvcx' => 'application/vnd.vcx',
+
+            'xvis' => 'application/vnd.visionary',
+            'xviv' => 'video/vnd.vivo',
+            'xvrml' => 'model/vrml',
+            'xvsd' => 'application/vnd.visio',
+            'xvsf' => 'application/vnd.vsf',
+            'xvss' => 'application/vnd.visio',
+            'xvst' => 'application/vnd.visio',
+            'xvsw' => 'application/vnd.visio',
+            'xvtu' => 'model/vnd.vtu',
+
+            'xvxml' => 'application/voicexml+xml',
+            'xwav' => 'audio/x-wav',
+            'xwax' => 'audio/x-ms-wax',
+            'xwbmp' => 'image/vnd.wap.wbmp',
+            'xwbs' => 'application/vnd.criticaltools.wbs+xml',
+            'xwbxml' => 'application/vnd.wap.wbxml',
+            'xwcm' => 'application/vnd.ms-works',
+            'xwdb' => 'application/vnd.ms-works',
+            'xwks' => 'application/vnd.ms-works',
+
+            'xwm' => 'video/x-ms-wm',
+            'xwma' => 'audio/x-ms-wma',
+            'xwmd' => 'application/x-ms-wmd',
+            'xwmf' => 'application/x-msmetafile',
+            'xwml' => 'text/vnd.wap.wml',
+            'xwmlc' => 'application/vnd.wap.wmlc',
+            'xwmls' => 'text/vnd.wap.wmlscript',
+            'xwmlsc' => 'application/vnd.wap.wmlscriptc',
+            'xwmv' => 'video/x-ms-wmv',
+
+            'xwmx' => 'video/x-ms-wmx',
+            'xwmz' => 'application/x-ms-wmz',
+            'xwpd' => 'application/vnd.wordperfect',
+            'xwpl' => 'application/vnd.ms-wpl',
+            'xwps' => 'application/vnd.ms-works',
+            'xwqd' => 'application/vnd.wqd',
+            'xwri' => 'application/x-mswrite',
+            'xwrl' => 'model/vrml',
+            'xwsdl' => 'application/wsdl+xml',
+
+            'xwspolicy' => 'application/wspolicy+xml',
+            'xwtb' => 'application/vnd.webturbo',
+            'xwvx' => 'video/x-ms-wvx',
+            'xx3d' => 'application/vnd.hzn-3d-crossword',
+            'xxar' => 'application/vnd.xara',
+            'xxbd' => 'application/vnd.fujixerox.docuworks.binder',
+            'xxbm' => 'image/x-xbitmap',
+            'xxdm' => 'application/vnd.syncml.dm+xml',
+            'xxdp' => 'application/vnd.adobe.xdp+xml',
+
+            'xxdw' => 'application/vnd.fujixerox.docuworks',
+            'xxenc' => 'application/xenc+xml',
+            'xxfdf' => 'application/vnd.adobe.xfdf',
+            'xxfdl' => 'application/vnd.xfdl',
+            'xxht' => 'application/xhtml+xml',
+            'xxhtml' => 'application/xhtml+xml',
+            'xxhvml' => 'application/xv+xml',
+            'xxif' => 'image/vnd.xiff',
+            'xxla' => 'application/vnd.ms-excel',
+
+            'xxlc' => 'application/vnd.ms-excel',
+            'xxlm' => 'application/vnd.ms-excel',
+            'xxls' => 'application/vnd.ms-excel',
+            'xxlt' => 'application/vnd.ms-excel',
+            'xxlw' => 'application/vnd.ms-excel',
+            'xxml' => 'application/xml',
+            'xxo' => 'application/vnd.olpc-sugar',
+            'xxop' => 'application/xop+xml',
+            'xxpm' => 'image/x-xpixmap',
+
+            'xxpr' => 'application/vnd.is-xpr',
+            'xxps' => 'application/vnd.ms-xpsdocument',
+            'xxsl' => 'application/xml',
+            'xxslt' => 'application/xslt+xml',
+            'xxsm' => 'application/vnd.syncml+xml',
+            'xxspf' => 'application/xspf+xml',
+            'xxul' => 'application/vnd.mozilla.xul+xml',
+            'xxvm' => 'application/xv+xml',
+            'xxvml' => 'application/xv+xml',
+
+            'xxwd' => 'image/x-xwindowdump',
+            'xxyz' => 'chemical/x-xyz',
+            'xzaz' => 'application/vnd.zzazz.deck+xml',
+            'xzip' => 'application/zip',
+            'xzmm' => 'application/vnd.handheld-entertainment+xml',
+        );
+
+    /**
+     * Extend list of MIME types if needed from config
+     */
+    public function __construct()
+    {
+        $nodes = Mage::getConfig()->getNode('global/mime/types');
+        if ($nodes) {
+            $nodes = (array)$nodes;
+            foreach ($nodes as $key => $value) {
+                $this->_mimeTypes[$key] = $value;
+            }
+        }
+    }
+
+    /**
+     * Get MIME type by file extension from list of pre-defined MIME types
+     *
+     * @param $ext
+     * @return string
+     */
+    public function getMimeTypeByExtension($ext)
+    {
+        $type = 'x' . $ext;
+        if (isset($this->_mimeTypes[$type])) {
+            return $this->_mimeTypes[$type];
+        }
+        return 'application/octet-stream';
+    }
+
+    /**
+     * Get all MIME Types
+     *
+     * @return array
+     */
+    public function getMimeTypes()
+    {
+        return $this->_mimeTypes;
+    }
+
+    /**
+     * Get array of MIME types associated with given file extension
+     *
+     * @param array|string $extensionsList
+     * @return array
+     */
+    public function getMimeTypeFromExtensionList($extensionsList)
+    {
+        if (is_string($extensionsList)) {
+            $extensionsList = array_map('trim', explode(',', $extensionsList));
+        }
+
+        return array_map(array($this, 'getMimeTypeByExtension'), $extensionsList);
+    }
+
+    /**
+     * Get post_max_size server setting
+     *
+     * @return string
+     */
+    public function getPostMaxSize()
+    {
+        return ini_get('post_max_size');
+    }
+
+    /**
+     * Get upload_max_filesize server setting
+     *
+     * @return string
+     */
+    public function getUploadMaxSize()
+    {
+        return ini_get('upload_max_filesize');
+    }
+
+    /**
+     * Get max upload size
+     *
+     * @return mixed
+     */
+    public function getDataMaxSize()
+    {
+        return min($this->getPostMaxSize(), $this->getUploadMaxSize());
+    }
+
+    /**
+     * Get maximum upload size in bytes
+     *
+     * @return int
+     */
+    public function getDataMaxSizeInBytes()
+    {
+        $iniSize = $this->getDataMaxSize();
+        $size = substr($iniSize, 0, strlen($iniSize)-1);
+        $parsedSize = 0;
+        switch (strtolower(substr($iniSize, strlen($iniSize)-1))) {
+            case 't':
+                $parsedSize = $size*(1024*1024*1024*1024);
+                break;
+            case 'g':
+                $parsedSize = $size*(1024*1024*1024);
+                break;
+            case 'm':
+                $parsedSize = $size*(1024*1024);
+                break;
+            case 'k':
+                $parsedSize = $size*1024;
+                break;
+            case 'b':
+            default:
+                $parsedSize = $size;
+                break;
+        }
+        return (int)$parsedSize;
+    }
+
+}
diff --git app/code/core/Mage/Uploader/Model/Config/Abstract.php app/code/core/Mage/Uploader/Model/Config/Abstract.php
new file mode 100644
index 0000000..da2ea63
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Abstract.php
@@ -0,0 +1,69 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+abstract class Mage_Uploader_Model_Config_Abstract extends Varien_Object
+{
+    /**
+     * Get file helper
+     *
+     * @return Mage_Uploader_Helper_File
+     */
+    protected function _getHelper()
+    {
+        return Mage::helper('uploader/file');
+    }
+
+    /**
+     * Set/Get attribute wrapper
+     * Also set data in cameCase for config values
+     *
+     * @param string $method
+     * @param array $args
+     * @return bool|mixed|Varien_Object
+     * @throws Varien_Exception
+     */
+    public function __call($method, $args)
+    {
+        $key = lcfirst($this->_camelize(substr($method,3)));
+        switch (substr($method, 0, 3)) {
+            case 'get' :
+                $data = $this->getData($key, isset($args[0]) ? $args[0] : null);
+                return $data;
+
+            case 'set' :
+                $result = $this->setData($key, isset($args[0]) ? $args[0] : null);
+                return $result;
+
+            case 'uns' :
+                $result = $this->unsetData($key);
+                return $result;
+
+            case 'has' :
+                return isset($this->_data[$key]);
+        }
+        throw new Varien_Exception("Invalid method ".get_class($this)."::".$method."(".print_r($args,1).")");
+    }
+}
diff --git app/code/core/Mage/Uploader/Model/Config/Browsebutton.php app/code/core/Mage/Uploader/Model/Config/Browsebutton.php
new file mode 100644
index 0000000..eaa5d64
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Browsebutton.php
@@ -0,0 +1,63 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+
+ * @method Mage_Uploader_Model_Config_Browsebutton setDomNodes(array $domNodesIds)
+ *      Array of element browse buttons ids
+ * @method Mage_Uploader_Model_Config_Browsebutton setIsDirectory(bool $isDirectory)
+ *      Pass in true to allow directories to be selected (Google Chrome only)
+ * @method Mage_Uploader_Model_Config_Browsebutton setSingleFile(bool $isSingleFile)
+ *      To prevent multiple file uploads set this to true.
+ *      Also look at config parameter singleFile (Mage_Uploader_Model_Config_Uploader setSingleFile())
+ * @method Mage_Uploader_Model_Config_Browsebutton setAttributes(array $attributes)
+ *      Pass object of keys and values to set custom attributes on input fields.
+ *      @see http://www.w3.org/TR/html-markup/input.file.html#input.file-attributes
+ */
+
+class Mage_Uploader_Model_Config_Browsebutton extends Mage_Uploader_Model_Config_Abstract
+{
+    /**
+     * Set params for browse button
+     */
+    protected function _construct()
+    {
+        $this->setIsDirectory(false);
+    }
+
+    /**
+     * Get MIME types from files extensions
+     *
+     * @param string|array $exts
+     * @return string
+     */
+    public function getMimeTypesByExtensions($exts)
+    {
+        $mimes = array_unique($this->_getHelper()->getMimeTypeFromExtensionList($exts));
+
+        // Not include general file type
+        unset($mimes['application/octet-stream']);
+
+        return implode(',', $mimes);
+    }
+}
diff --git app/code/core/Mage/Uploader/Model/Config/Misc.php app/code/core/Mage/Uploader/Model/Config/Misc.php
new file mode 100644
index 0000000..3c70ad3
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Misc.php
@@ -0,0 +1,46 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ * 
+ * @method Mage_Uploader_Model_Config_Misc setMaxSizePlural (string $sizePlural) Set plural info about max upload size
+ * @method Mage_Uploader_Model_Config_Misc setMaxSizeInBytes (int $sizeInBytes) Set max upload size in bytes
+ * @method Mage_Uploader_Model_Config_Misc setReplaceBrowseWithRemove (bool $replaceBrowseWithRemove)
+ *      Replace browse button with remove
+ *
+ * Class Mage_Uploader_Model_Config_Misc
+ */
+
+class Mage_Uploader_Model_Config_Misc extends Mage_Uploader_Model_Config_Abstract
+{
+    /**
+     * Prepare misc params
+     */
+    protected function _construct()
+    {
+        $this
+            ->setMaxSizeInBytes($this->_getHelper()->getDataMaxSizeInBytes())
+            ->setMaxSizePlural($this->_getHelper()->getDataMaxSize())
+        ;
+    }
+}
diff --git app/code/core/Mage/Uploader/Model/Config/Uploader.php app/code/core/Mage/Uploader/Model/Config/Uploader.php
new file mode 100644
index 0000000..0fc6f0c
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Uploader.php
@@ -0,0 +1,122 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/**
+ * @method Mage_Uploader_Model_Config_Uploader setTarget(string $url)
+ *      The target URL for the multipart POST request.
+ * @method Mage_Uploader_Model_Config_Uploader setSingleFile(bool $isSingleFile)
+ *      Enable single file upload.
+ *      Once one file is uploaded, second file will overtake existing one, first one will be canceled.
+ * @method Mage_Uploader_Model_Config_Uploader setChunkSize(int $chunkSize) The size in bytes of each uploaded chunk of data.
+ * @method Mage_Uploader_Model_Config_Uploader setForceChunkSize(bool $forceChunkSize)
+ *      Force all chunks to be less or equal than chunkSize.
+ * @method Mage_Uploader_Model_Config_Uploader setSimultaneousUploads(int $amountOfSimultaneousUploads)
+ * @method Mage_Uploader_Model_Config_Uploader setFileParameterName(string $fileUploadParam)
+ * @method Mage_Uploader_Model_Config_Uploader setQuery(array $additionalQuery)
+ * @method Mage_Uploader_Model_Config_Uploader setHeaders(array $headers)
+ *      Extra headers to include in the multipart POST with data.
+ * @method Mage_Uploader_Model_Config_Uploader setWithCredentials(bool $isCORS)
+ *      Standard CORS requests do not send or set any cookies by default.
+ *      In order to include cookies as part of the request, you need to set the withCredentials property to true.
+ * @method Mage_Uploader_Model_Config_Uploader setMethod(string $sendMethod)
+ *       Method to use when POSTing chunks to the server. Defaults to "multipart"
+ * @method Mage_Uploader_Model_Config_Uploader setTestMethod(string $testMethod) Defaults to "GET"
+ * @method Mage_Uploader_Model_Config_Uploader setUploadMethod(string $uploadMethod) Defaults to "POST"
+ * @method Mage_Uploader_Model_Config_Uploader setAllowDuplicateUploads(bool $allowDuplicateUploads)
+ *      Once a file is uploaded, allow reupload of the same file. By default, if a file is already uploaded,
+ *      it will be skipped unless the file is removed from the existing Flow object.
+ * @method Mage_Uploader_Model_Config_Uploader setPrioritizeFirstAndLastChunk(bool $prioritizeFirstAndLastChunk)
+ *      This can be handy if you can determine if a file is valid for your service from only the first or last chunk.
+ * @method Mage_Uploader_Model_Config_Uploader setTestChunks(bool $prioritizeFirstAndLastChunk)
+ *      Make a GET request to the server for each chunks to see if it already exists.
+ * @method Mage_Uploader_Model_Config_Uploader setPreprocess(bool $prioritizeFirstAndLastChunk)
+ *      Optional function to process each chunk before testing & sending.
+ * @method Mage_Uploader_Model_Config_Uploader setInitFileFn(string $function)
+ *      Optional function to initialize the fileObject (js).
+ * @method Mage_Uploader_Model_Config_Uploader setReadFileFn(string $function)
+ *      Optional function wrapping reading operation from the original file.
+ * @method Mage_Uploader_Model_Config_Uploader setGenerateUniqueIdentifier(string $function)
+ *      Override the function that generates unique identifiers for each file. Defaults to "null"
+ * @method Mage_Uploader_Model_Config_Uploader setMaxChunkRetries(int $maxChunkRetries) Defaults to 0
+ * @method Mage_Uploader_Model_Config_Uploader setChunkRetryInterval(int $chunkRetryInterval) Defaults to "undefined"
+ * @method Mage_Uploader_Model_Config_Uploader setProgressCallbacksInterval(int $progressCallbacksInterval)
+ * @method Mage_Uploader_Model_Config_Uploader setSpeedSmoothingFactor(int $speedSmoothingFactor)
+ *      Used for calculating average upload speed. Number from 1 to 0.
+ *      Set to 1 and average upload speed wil be equal to current upload speed.
+ *      For longer file uploads it is better set this number to 0.02,
+ *      because time remaining estimation will be more accurate.
+ * @method Mage_Uploader_Model_Config_Uploader setSuccessStatuses(array $successStatuses)
+ *      Response is success if response status is in this list
+ * @method Mage_Uploader_Model_Config_Uploader setPermanentErrors(array $permanentErrors)
+ *      Response fails if response status is in this list
+ *
+ * Class Mage_Uploader_Model_Config_Uploader
+ */
+
+class Mage_Uploader_Model_Config_Uploader extends Mage_Uploader_Model_Config_Abstract
+{
+    /**
+     * Type of upload
+     */
+    const UPLOAD_TYPE = 'multipart';
+
+    /**
+     * Test chunks on resumable uploads
+     */
+    const TEST_CHUNKS = false;
+
+    /**
+     * Used for calculating average upload speed.
+     */
+    const SMOOTH_UPLOAD_FACTOR = 0.02;
+
+    /**
+     * Progress check interval
+     */
+    const PROGRESS_CALLBACK_INTERVAL = 0;
+
+    /**
+     * Set default values for uploader
+     */
+    protected function _construct()
+    {
+        $this
+            ->setChunkSize($this->_getHelper()->getDataMaxSizeInBytes())
+            ->setWithCredentials(false)
+            ->setForceChunkSize(false)
+            ->setQuery(array(
+                'form_key' => Mage::getSingleton('core/session')->getFormKey()
+            ))
+            ->setMethod(self::UPLOAD_TYPE)
+            ->setAllowDuplicateUploads(true)
+            ->setPrioritizeFirstAndLastChunk(false)
+            ->setTestChunks(self::TEST_CHUNKS)
+            ->setSpeedSmoothingFactor(self::SMOOTH_UPLOAD_FACTOR)
+            ->setProgressCallbacksInterval(self::PROGRESS_CALLBACK_INTERVAL)
+            ->setSuccessStatuses(array(200, 201, 202))
+            ->setPermanentErrors(array(404, 415, 500, 501));
+    }
+}
diff --git app/code/core/Mage/Uploader/etc/config.xml app/code/core/Mage/Uploader/etc/config.xml
new file mode 100644
index 0000000..78584d5
--- /dev/null
+++ app/code/core/Mage/Uploader/etc/config.xml
@@ -0,0 +1,51 @@
+<?xml version="1.0"?>
+<!--
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+-->
+<config>
+    <modules>
+        <Mage_Uploader>
+            <version>0.1.0</version>
+        </Mage_Uploader>
+    </modules>
+    <global>
+        <blocks>
+            <uploader>
+                <class>Mage_Uploader_Block</class>
+            </uploader>
+        </blocks>
+        <helpers>
+            <uploader>
+                <class>Mage_Uploader_Helper</class>
+            </uploader>
+        </helpers>
+        <models>
+            <uploader>
+                <class>Mage_Uploader_Model</class>
+            </uploader>
+        </models>
+    </global>
+</config>
diff --git app/code/core/Mage/Uploader/etc/jstranslator.xml app/code/core/Mage/Uploader/etc/jstranslator.xml
new file mode 100644
index 0000000..8b1fe0a
--- /dev/null
+++ app/code/core/Mage/Uploader/etc/jstranslator.xml
@@ -0,0 +1,44 @@
+<?xml version="1.0"?>
+<!--
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+-->
+<jstranslator>
+    <uploader-exceed_max-1 translate="message" module="uploader">
+        <message>Maximum allowed file size for upload is</message>
+    </uploader-exceed_max-1>
+    <uploader-exceed_max-2 translate="message" module="uploader">
+        <message>Please check your server PHP settings.</message>
+    </uploader-exceed_max-2>
+    <uploader-tab-change-event-confirm translate="message" module="uploader">
+        <message>There are files that were selected but not uploaded yet. After switching to another tab your selections will be lost. Do you wish to continue ?</message>
+    </uploader-tab-change-event-confirm>
+    <uploader-complete-event-text translate="message" module="uploader">
+        <message>Complete</message>
+    </uploader-complete-event-text>
+    <uploader-uploading-progress translate="message" module="uploader">
+        <message>Uploading...</message>
+    </uploader-uploading-progress>
+</jstranslator>
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php
index 1612648..541e7f6 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php
@@ -566,8 +566,8 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl
                 $ch = curl_init();
                 curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
                 curl_setopt($ch, CURLOPT_URL, $url);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
+                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
+                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
                 curl_setopt($ch, CURLOPT_POSTFIELDS, $request);
                 $responseBody = curl_exec($ch);
                 curl_close($ch);
@@ -1070,8 +1070,8 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl
             $ch = curl_init();
             curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
             curl_setopt($ch, CURLOPT_URL, $url);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
+            curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
             curl_setopt($ch, CURLOPT_POSTFIELDS, $request);
             $responseBody = curl_exec($ch);
             $debugData['result'] = $responseBody;
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php
index 26e7771..caa6d6f 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php
@@ -841,7 +841,12 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl_International
             try {
                 $client = new Varien_Http_Client();
                 $client->setUri((string)$this->getConfigData('gateway_url'));
-                $client->setConfig(array('maxredirects' => 0, 'timeout' => 30));
+                $client->setConfig(array(
+                    'maxredirects' => 0,
+                    'timeout' => 30,
+                    'verifypeer' => $this->getConfigFlag('verify_peer'),
+                    'verifyhost' => 2,
+                ));
                 $client->setRawData($request);
                 $responseBody = $client->request(Varien_Http_Client::POST)->getBody();
                 $debugData['result'] = $responseBody;
@@ -1362,7 +1367,12 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl_International
             try {
                 $client = new Varien_Http_Client();
                 $client->setUri((string)$this->getConfigData('gateway_url'));
-                $client->setConfig(array('maxredirects' => 0, 'timeout' => 30));
+                $client->setConfig(array(
+                    'maxredirects' => 0,
+                    'timeout' => 30,
+                    'verifypeer' => $this->getConfigFlag('verify_peer'),
+                    'verifyhost' => 2,
+                ));
                 $client->setRawData($request);
                 $responseBody = $client->request(Varien_Http_Client::POST)->getBody();
                 $debugData['result'] = $responseBody;
@@ -1554,7 +1564,12 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl_International
             try {
                 $client = new Varien_Http_Client();
                 $client->setUri((string)$this->getConfigData('gateway_url'));
-                $client->setConfig(array('maxredirects' => 0, 'timeout' => 30));
+                $client->setConfig(array(
+                    'maxredirects' => 0,
+                    'timeout' => 30,
+                    'verifypeer' => $this->getConfigFlag('verify_peer'),
+                    'verifyhost' => 2,
+                ));
                 $client->setRawData($request);
                 $responseBody = $client->request(Varien_Http_Client::POST)->getBody();
                 $debugData['result'] = $responseBody;
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php
index 39e5af8..2f34f3f 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php
@@ -563,6 +563,7 @@ class Mage_Usa_Model_Shipping_Carrier_Fedex
     /**
      * Get xml quotes
      *
+     * @deprecated
      * @return Mage_Shipping_Model_Rate_Result
      */
     protected function _getXmlQuotes()
@@ -622,8 +623,8 @@ class Mage_Usa_Model_Shipping_Carrier_Fedex
                 $ch = curl_init();
                 curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
                 curl_setopt($ch, CURLOPT_URL, $url);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
+                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 1);
+                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
                 curl_setopt($ch, CURLOPT_POSTFIELDS, $request);
                 $responseBody = curl_exec($ch);
                 curl_close ($ch);
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php
index c324af8..c203e06 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php
@@ -932,7 +932,7 @@ XMLRequest;
                 curl_setopt($ch, CURLOPT_POST, 1);
                 curl_setopt($ch, CURLOPT_POSTFIELDS, $xmlRequest);
                 curl_setopt($ch, CURLOPT_TIMEOUT, 30);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, (boolean)$this->getConfigFlag('mode_xml'));
+                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
                 $xmlResponse = curl_exec ($ch);
 
                 $debugData['result'] = $xmlResponse;
@@ -1567,7 +1567,7 @@ XMLAuth;
             curl_setopt($ch, CURLOPT_POST, 1);
             curl_setopt($ch, CURLOPT_POSTFIELDS, $this->_xmlAccessRequest . $xmlRequest->asXML());
             curl_setopt($ch, CURLOPT_TIMEOUT, 30);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, (boolean)$this->getConfigFlag('mode_xml'));
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
             $xmlResponse = curl_exec ($ch);
 
             $debugData['result'] = $xmlResponse;
@@ -1625,7 +1625,7 @@ XMLAuth;
             curl_setopt($ch, CURLOPT_POST, 1);
             curl_setopt($ch, CURLOPT_POSTFIELDS, $xmlRequest);
             curl_setopt($ch, CURLOPT_TIMEOUT, 30);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, (boolean)$this->getConfigFlag('mode_xml'));
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
             $xmlResponse = curl_exec($ch);
             if ($xmlResponse === false) {
                 throw new Exception(curl_error($ch));
diff --git app/code/core/Mage/Usa/etc/config.xml app/code/core/Mage/Usa/etc/config.xml
index 5eaa96c..ef4f566 100644
--- app/code/core/Mage/Usa/etc/config.xml
+++ app/code/core/Mage/Usa/etc/config.xml
@@ -114,6 +114,7 @@
                 <dutypaymenttype>R</dutypaymenttype>
                 <free_method>G</free_method>
                 <gateway_url>https://eCommerce.airborne.com/ApiLandingTest.asp</gateway_url>
+                <verify_peer>0</verify_peer>
                 <id backend_model="adminhtml/system_config_backend_encrypted"/>
                 <model>usa/shipping_carrier_dhl</model>
                 <password backend_model="adminhtml/system_config_backend_encrypted"/>
@@ -181,6 +182,7 @@
                 <negotiated_active>0</negotiated_active>
                 <mode_xml>1</mode_xml>
                 <type>UPS</type>
+                <verify_peer>0</verify_peer>
             </ups>
             <usps>
                 <active>0</active>
@@ -216,6 +218,7 @@
                 <doc_methods>2,5,6,7,9,B,C,D,U,K,L,G,W,I,N,O,R,S,T,X</doc_methods>
                 <free_method>G</free_method>
                 <gateway_url>https://xmlpi-ea.dhl.com/XMLShippingServlet</gateway_url>
+                <verify_peer>0</verify_peer>
                 <id backend_model="adminhtml/system_config_backend_encrypted"/>
                 <password backend_model="adminhtml/system_config_backend_encrypted"/>
                 <shipment_type>N</shipment_type>
diff --git app/code/core/Mage/Usa/etc/system.xml app/code/core/Mage/Usa/etc/system.xml
index 8c642a1..3342f7f 100644
--- app/code/core/Mage/Usa/etc/system.xml
+++ app/code/core/Mage/Usa/etc/system.xml
@@ -130,6 +130,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
                         </gateway_url>
+                        <verify_peer translate="label">
+                            <label>Enable SSL Verification</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>30</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </verify_peer>
                         <handling_type translate="label">
                             <label>Calculate Handling Fee</label>
                             <frontend_type>select</frontend_type>
@@ -735,6 +744,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
                         </gateway_url>
+                        <verify_peer translate="label">
+                            <label>Enable SSL Verification</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>45</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </verify_peer>
                         <gateway_xml_url translate="label">
                             <label>Gateway XML URL</label>
                             <frontend_type>text</frontend_type>
@@ -1239,6 +1257,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
                         </gateway_url>
+                        <verify_peer translate="label">
+                            <label>Enable SSL Verification</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>30</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </verify_peer>
                         <title translate="label">
                             <label>Title</label>
                             <frontend_type>text</frontend_type>
diff --git app/code/core/Mage/Wishlist/Controller/Abstract.php app/code/core/Mage/Wishlist/Controller/Abstract.php
index 7d193a2..f2124b9 100644
--- app/code/core/Mage/Wishlist/Controller/Abstract.php
+++ app/code/core/Mage/Wishlist/Controller/Abstract.php
@@ -73,10 +73,15 @@ abstract class Mage_Wishlist_Controller_Abstract extends Mage_Core_Controller_Fr
      */
     public function allcartAction()
     {
+        if (!$this->_validateFormKey()) {
+            $this->_forward('noRoute');
+            return;
+        }
+
         $wishlist   = $this->_getWishlist();
         if (!$wishlist) {
             $this->_forward('noRoute');
-            return ;
+            return;
         }
         $isOwner    = $wishlist->isOwner(Mage::getSingleton('customer/session')->getCustomerId());
 
@@ -89,7 +94,9 @@ abstract class Mage_Wishlist_Controller_Abstract extends Mage_Core_Controller_Fr
         $collection = $wishlist->getItemCollection()
                 ->setVisibilityFilter();
 
-        $qtys = $this->getRequest()->getParam('qty');
+        $qtysString = $this->getRequest()->getParam('qty');
+        $qtys =  array_filter(json_decode($qtysString), 'strlen');
+
         foreach ($collection as $item) {
             /** @var Mage_Wishlist_Model_Item */
             try {
diff --git app/code/core/Mage/Wishlist/Helper/Data.php app/code/core/Mage/Wishlist/Helper/Data.php
index d79ac4c..288d570 100644
--- app/code/core/Mage/Wishlist/Helper/Data.php
+++ app/code/core/Mage/Wishlist/Helper/Data.php
@@ -135,11 +135,9 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
         if (is_null($this->_wishlist)) {
             if (Mage::registry('shared_wishlist')) {
                 $this->_wishlist = Mage::registry('shared_wishlist');
-            }
-            elseif (Mage::registry('wishlist')) {
+            } else if (Mage::registry('wishlist')) {
                 $this->_wishlist = Mage::registry('wishlist');
-            }
-            else {
+            } else {
                 $this->_wishlist = Mage::getModel('wishlist/wishlist');
                 if ($this->getCustomer()) {
                     $this->_wishlist->loadByCustomer($this->getCustomer());
@@ -260,8 +258,7 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
         if ($product) {
             if ($product->isVisibleInSiteVisibility()) {
                 $storeId = $product->getStoreId();
-            }
-            else if ($product->hasUrlDataObject()) {
+            } else if ($product->hasUrlDataObject()) {
                 $storeId = $product->getUrlDataObject()->getStoreId();
             }
         }
@@ -277,7 +274,10 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
     public function getRemoveUrl($item)
     {
         return $this->_getUrl('wishlist/index/remove',
-            array('item' => $item->getWishlistItemId())
+            array(
+                'item' => $item->getWishlistItemId(),
+                Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
+            )
         );
     }
 
@@ -360,40 +360,62 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
             $productId = $item->getProductId();
         }
 
-        if ($productId) {
-            $params['product'] = $productId;
-            return $this->_getUrlStore($item)->getUrl('wishlist/index/add', $params);
+        if (!$productId) {
+            return false;
         }
-
-        return false;
+        $params['product'] = $productId;
+        $params[Mage_Core_Model_Url::FORM_KEY] = $this->_getSingletonModel('core/session')->getFormKey();
+        return $this->_getUrlStore($item)->getUrl('wishlist/index/add', $params);
     }
 
     /**
-     * Retrieve URL for adding item to shoping cart
+     * Retrieve URL for adding item to shopping cart
      *
      * @param string|Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
      * @return  string
      */
     public function getAddToCartUrl($item)
     {
-        $urlParamName = Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED;
-        $continueUrl  = Mage::helper('core')->urlEncode(
-            Mage::getUrl('*/*/*', array(
+        $continueUrl  = $this->_getHelperInstance('core')->urlEncode(
+            $this->_getUrl('*/*/*', array(
                 '_current'      => true,
                 '_use_rewrite'  => true,
                 '_store_to_url' => true,
             ))
         );
-
-        $urlParamName = Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED;
         $params = array(
             'item' => is_string($item) ? $item : $item->getWishlistItemId(),
-            $urlParamName => $continueUrl
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $continueUrl,
+            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
         );
+
         return $this->_getUrlStore($item)->getUrl('wishlist/index/cart', $params);
     }
 
     /**
+     * Return helper instance
+     *
+     * @param string $helperName
+     * @return Mage_Core_Helper_Abstract
+     */
+    protected function _getHelperInstance($helperName)
+    {
+        return Mage::helper($helperName);
+    }
+
+    /**
+     * Return model instance
+     *
+     * @param string $className
+     * @param array $arguments
+     * @return Mage_Core_Model_Abstract
+     */
+    protected function _getSingletonModel($className, $arguments = array())
+    {
+        return Mage::getSingleton($className, $arguments);
+    }
+
+    /**
      * Retrieve URL for adding item to shoping cart from shared wishlist
      *
      * @param string|Mage_Catalog_Model_Product|Mage_Wishlist_Model_Item $item
@@ -407,10 +429,10 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
             '_store_to_url' => true,
         )));
 
-        $urlParamName = Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED;
         $params = array(
             'item' => is_string($item) ? $item : $item->getWishlistItemId(),
-            $urlParamName => $continueUrl
+            Mage_Core_Controller_Front_Action::PARAM_NAME_URL_ENCODED => $continueUrl,
+            Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
         );
         return $this->_getUrlStore($item)->getUrl('wishlist/shared/cart', $params);
     }
diff --git app/code/core/Mage/Wishlist/controllers/IndexController.php app/code/core/Mage/Wishlist/controllers/IndexController.php
index 4018eb0..beaf174 100644
--- app/code/core/Mage/Wishlist/controllers/IndexController.php
+++ app/code/core/Mage/Wishlist/controllers/IndexController.php
@@ -48,6 +48,11 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
      */
     protected $_skipAuthentication = false;
 
+    /**
+     * Extend preDispatch
+     *
+     * @return Mage_Core_Controller_Front_Action|void
+     */
     public function preDispatch()
     {
         parent::preDispatch();
@@ -152,9 +157,24 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
 
     /**
      * Adding new item
+     *
+     * @return Mage_Core_Controller_Varien_Action|void
      */
     public function addAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
+        $this->_addItemToWishList();
+    }
+
+    /**
+     * Add the item to wish list
+     *
+     * @return Mage_Core_Controller_Varien_Action|void
+     */
+    protected function _addItemToWishList()
+    {
         $wishlist = $this->_getWishlist();
         if (!$wishlist) {
             return $this->norouteAction();
@@ -162,7 +182,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
 
         $session = Mage::getSingleton('customer/session');
 
-        $productId = (int) $this->getRequest()->getParam('product');
+        $productId = (int)$this->getRequest()->getParam('product');
         if (!$productId) {
             $this->_redirect('*/');
             return;
@@ -192,9 +212,9 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
             Mage::dispatchEvent(
                 'wishlist_add_product',
                 array(
-                    'wishlist'  => $wishlist,
-                    'product'   => $product,
-                    'item'      => $result
+                    'wishlist' => $wishlist,
+                    'product' => $product,
+                    'item' => $result
                 )
             );
 
@@ -212,10 +232,10 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
 
             Mage::helper('wishlist')->calculate();
 
-            $message = $this->__('%1$s has been added to your wishlist. Click <a href="%2$s">here</a> to continue shopping.', $product->getName(), Mage::helper('core')->escapeUrl($referer));
+            $message = $this->__('%1$s has been added to your wishlist. Click <a href="%2$s">here</a> to continue shopping.',
+                $product->getName(), Mage::helper('core')->escapeUrl($referer));
             $session->addSuccess($message);
-        }
-        catch (Mage_Core_Exception $e) {
+        } catch (Mage_Core_Exception $e) {
             $session->addError($this->__('An error occurred while adding item to wishlist: %s', $e->getMessage()));
         }
         catch (Exception $e) {
@@ -337,7 +357,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
         }
 
         $post = $this->getRequest()->getPost();
-        if($post && isset($post['description']) && is_array($post['description'])) {
+        if ($post && isset($post['description']) && is_array($post['description'])) {
             $updatedItems = 0;
 
             foreach ($post['description'] as $itemId => $description) {
@@ -393,8 +413,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
                 try {
                     $wishlist->save();
                     Mage::helper('wishlist')->calculate();
-                }
-                catch (Exception $e) {
+                } catch (Exception $e) {
                     Mage::getSingleton('customer/session')->addError($this->__('Can\'t update wishlist'));
                 }
             }
@@ -412,6 +431,9 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
      */
     public function removeAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
         $id = (int) $this->getRequest()->getParam('item');
         $item = Mage::getModel('wishlist/item')->load($id);
         if (!$item->getId()) {
@@ -428,7 +450,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
             Mage::getSingleton('customer/session')->addError(
                 $this->__('An error occurred while deleting the item from wishlist: %s', $e->getMessage())
             );
-        } catch(Exception $e) {
+        } catch (Exception $e) {
             Mage::getSingleton('customer/session')->addError(
                 $this->__('An error occurred while deleting the item from wishlist.')
             );
@@ -447,6 +469,9 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
      */
     public function cartAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
         $itemId = (int) $this->getRequest()->getParam('item');
 
         /* @var $item Mage_Wishlist_Model_Item */
@@ -536,7 +561,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
         $cart = Mage::getSingleton('checkout/cart');
         $session = Mage::getSingleton('checkout/session');
 
-        try{
+        try {
             $item = $cart->getQuote()->getItemById($itemId);
             if (!$item) {
                 Mage::throwException(
@@ -632,7 +657,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
                     ->createBlock('wishlist/share_email_rss')
                     ->setWishlistId($wishlist->getId())
                     ->toHtml();
-                $message .=$rss_url;
+                $message .= $rss_url;
             }
             $wishlistBlock = $this->getLayout()->createBlock('wishlist/share_email_items')->toHtml();
 
@@ -641,19 +666,19 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
             $emailModel = Mage::getModel('core/email_template');
 
             $sharingCode = $wishlist->getSharingCode();
-            foreach($emails as $email) {
+            foreach ($emails as $email) {
                 $emailModel->sendTransactional(
                     Mage::getStoreConfig('wishlist/email/email_template'),
                     Mage::getStoreConfig('wishlist/email/email_identity'),
                     $email,
                     null,
                     array(
-                        'customer'      => $customer,
-                        'salable'       => $wishlist->isSalable() ? 'yes' : '',
-                        'items'         => $wishlistBlock,
-                        'addAllLink'    => Mage::getUrl('*/shared/allcart', array('code' => $sharingCode)),
-                        'viewOnSiteLink'=> Mage::getUrl('*/shared/index', array('code' => $sharingCode)),
-                        'message'       => $message
+                        'customer'       => $customer,
+                        'salable'        => $wishlist->isSalable() ? 'yes' : '',
+                        'items'          => $wishlistBlock,
+                        'addAllLink'     => Mage::getUrl('*/shared/allcart', array('code' => $sharingCode)),
+                        'viewOnSiteLink' => Mage::getUrl('*/shared/index', array('code' => $sharingCode)),
+                        'message'        => $message
                     )
                 );
             }
@@ -663,7 +688,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
 
             $translate->setTranslateInline(true);
 
-            Mage::dispatchEvent('wishlist_share', array('wishlist'=>$wishlist));
+            Mage::dispatchEvent('wishlist_share', array('wishlist' => $wishlist));
             Mage::getSingleton('customer/session')->addSuccess(
                 $this->__('Your Wishlist has been shared.')
             );
@@ -719,7 +744,7 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
                 ));
             }
 
-        } catch(Exception $e) {
+        } catch (Exception $e) {
             $this->_forward('noRoute');
         }
         exit(0);
diff --git app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php
index 196ce8d..34179f4 100644
--- app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php
+++ app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php
@@ -95,4 +95,21 @@ class Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design
     {
         return true;
     }
+
+    /**
+     * Create browse button template
+     *
+     * @return string
+     */
+    public function getBrowseButtonHtml()
+    {
+        return $this->getLayout()->createBlock('adminhtml/widget_button')
+            ->addData(array(
+                'before_html'   => '<div style="display:inline-block; " id="{{file_field}}_{{id}}_file-browse">',
+                'after_html'    => '</div>',
+                'id'            => '{{file_field}}_{{id}}_file-browse_button',
+                'label'         => Mage::helper('uploader')->__('...'),
+                'type'          => 'button',
+            ))->toHtml();
+    }
 }
diff --git app/design/adminhtml/default/default/layout/cms.xml app/design/adminhtml/default/default/layout/cms.xml
index 501cd3d..555f0ef 100644
--- app/design/adminhtml/default/default/layout/cms.xml
+++ app/design/adminhtml/default/default/layout/cms.xml
@@ -82,7 +82,9 @@
         </reference>
         <reference name="content">
             <block name="wysiwyg_images.content"  type="adminhtml/cms_wysiwyg_images_content" template="cms/browser/content.phtml">
-                <block name="wysiwyg_images.uploader" type="adminhtml/cms_wysiwyg_images_content_uploader" template="cms/browser/content/uploader.phtml" />
+                <block name="wysiwyg_images.uploader" type="adminhtml/cms_wysiwyg_images_content_uploader" template="media/uploader.phtml">
+                    <block name="additional_scripts" type="core/template" template="cms/browser/content/uploader.phtml"/>
+                </block>
                 <block name="wysiwyg_images.newfolder" type="adminhtml/cms_wysiwyg_images_content_newfolder" template="cms/browser/content/newfolder.phtml" />
             </block>
         </reference>
diff --git app/design/adminhtml/default/default/layout/main.xml app/design/adminhtml/default/default/layout/main.xml
index 26e9ace..01f8bb1 100644
--- app/design/adminhtml/default/default/layout/main.xml
+++ app/design/adminhtml/default/default/layout/main.xml
@@ -170,9 +170,10 @@ Layout for editor element
             <action method="setCanLoadExtJs"><flag>1</flag></action>
             <action method="addJs"><script>mage/adminhtml/variables.js</script></action>
             <action method="addJs"><script>mage/adminhtml/wysiwyg/widget.js</script></action>
-            <action method="addJs"><script>lib/flex.js</script></action>
-            <action method="addJs"><script>lib/FABridge.js</script></action>
-            <action method="addJs"><script>mage/adminhtml/flexuploader.js</script></action>
+            <action method="addJs"><name>lib/uploader/flow.min.js</name></action>
+            <action method="addJs"><name>lib/uploader/fusty-flow.js</name></action>
+            <action method="addJs"><name>lib/uploader/fusty-flow-factory.js</name></action>
+            <action method="addJs"><name>mage/adminhtml/uploader/instance.js</name></action>
             <action method="addJs"><script>mage/adminhtml/browser.js</script></action>
             <action method="addJs"><script>prototype/window.js</script></action>
             <action method="addItem"><type>js_css</type><name>prototype/windows/themes/default.css</name></action>
diff --git app/design/adminhtml/default/default/layout/xmlconnect.xml app/design/adminhtml/default/default/layout/xmlconnect.xml
index 05f0e0d..d859266 100644
--- app/design/adminhtml/default/default/layout/xmlconnect.xml
+++ app/design/adminhtml/default/default/layout/xmlconnect.xml
@@ -74,9 +74,10 @@
             <action method="setCanLoadExtJs"><flag>1</flag></action>
             <action method="addJs"><script>mage/adminhtml/variables.js</script></action>
             <action method="addJs"><script>mage/adminhtml/wysiwyg/widget.js</script></action>
-            <action method="addJs"><script>lib/flex.js</script></action>
-            <action method="addJs"><script>lib/FABridge.js</script></action>
-            <action method="addJs"><script>mage/adminhtml/flexuploader.js</script></action>
+             <action method="addJs"><name>lib/uploader/flow.min.js</name></action>
+             <action method="addJs"><name>lib/uploader/fusty-flow.js</name></action>
+             <action method="addJs"><name>lib/uploader/fusty-flow-factory.js</name></action>
+             <action method="addJs"><name>mage/adminhtml/uploader/instance.js</name></action>
             <action method="addJs"><script>mage/adminhtml/browser.js</script></action>
             <action method="addJs"><script>prototype/window.js</script></action>
             <action method="addItem"><type>js_css</type><name>prototype/windows/themes/default.css</name></action>
diff --git app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
index 170c422..8b67075 100644
--- app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
@@ -108,6 +108,7 @@ $_block = $this;
     <tfoot>
         <tr>
             <td colspan="100" class="last" style="padding:8px">
+                <?php echo Mage::helper('catalog')->__('Maximum width and height dimension for upload image is %s.', Mage::getStoreConfig(Mage_Catalog_Helper_Image::XML_NODE_PRODUCT_MAX_DIMENSION)); ?>
                 <?php echo $_block->getUploaderHtml() ?>
             </td>
         </tr>
@@ -120,6 +121,6 @@ $_block = $this;
 <input type="hidden" id="<?php echo $_block->getHtmlId() ?>_save_image" name="<?php echo $_block->getElement()->getName() ?>[values]" value="<?php echo $_block->htmlEscape($_block->getImagesValuesJson()) ?>" />
 <script type="text/javascript">
 //<![CDATA[
-var <?php echo $_block->getJsObjectName(); ?> = new Product.Gallery('<?php echo $_block->getHtmlId() ?>', <?php if ($_block->getElement()->getReadonly()):?>null<?php else:?><?php echo $_block->getUploader()->getJsObjectName() ?><?php endif;?>, <?php echo $_block->getImageTypesJson() ?>);
+var <?php echo $_block->getJsObjectName(); ?> = new Product.Gallery('<?php echo $_block->getHtmlId() ?>', <?php echo $_block->getImageTypesJson() ?>);
 //]]>
 </script>
diff --git app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml
index 41dfcfe..e2b3800 100644
--- app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml
+++ app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml
@@ -24,48 +24,8 @@
  * @license     http://www.magentocommerce.com/license/enterprise-edition
  */
 ?>
-<?php
-/**
- * Uploader template for Wysiwyg Images
- *
- * @see Mage_Adminhtml_Block_Cms_Wysiwyg_Images_Content_Uploader
- */
-?>
-<div id="<?php echo $this->getHtmlId() ?>" class="uploader">
-    <div class="buttons">
-        <div id="<?php echo $this->getHtmlId() ?>-install-flash" style="display:none">
-            <?php echo Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/') ?>
-        </div>
-    </div>
-    <div class="clear"></div>
-    <div class="no-display" id="<?php echo $this->getHtmlId() ?>-template">
-        <div id="{{id}}" class="file-row">
-        <span class="file-info">{{name}} ({{size}})</span>
-        <span class="delete-button"><?php echo $this->getDeleteButtonHtml() ?></span>
-        <span class="progress-text"></span>
-        <div class="clear"></div>
-        </div>
-    </div>
-    <div class="no-display" id="<?php echo $this->getHtmlId() ?>-template-progress">
-        {{percent}}% {{uploaded}} / {{total}}
-    </div>
-</div>
-
 <script type="text/javascript">
 //<![CDATA[
-maxUploadFileSizeInBytes = <?php echo $this->getDataMaxSizeInBytes() ?>;
-maxUploadFileSize = '<?php echo $this->getDataMaxSize() ?>';
-
-<?php echo $this->getJsObjectName() ?> = new Flex.Uploader('<?php echo $this->getHtmlId() ?>', '<?php echo $this->getSkinUrl('media/uploader.swf') ?>', <?php echo $this->getConfigJson() ?>);
-<?php echo $this->getJsObjectName() ?>.onFilesComplete = function(completedFiles){
-    completedFiles.each(function(file){
-        <?php echo $this->getJsObjectName() ?>.removeFile(file.id);
-    });
-    MediabrowserInstance.handleUploadComplete();
-}
-// hide flash buttons
-if ($('<?php echo $this->getHtmlId() ?>-flash') != undefined) {
-    $('<?php echo $this->getHtmlId() ?>-flash').setStyle({float:'left'});
-}
+    document.on('uploader:success', MediabrowserInstance.handleUploadComplete.bind(MediabrowserInstance));
 //]]>
 </script>
diff --git app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable.phtml app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable.phtml
index 17b32d3..b57ec35 100644
--- app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable.phtml
@@ -34,19 +34,16 @@
 //<![CDATA[>
 
 var uploaderTemplate = '<div class="no-display" id="[[idName]]-template">' +
-                            '<div id="{{id}}" class="file-row file-row-narrow">' +
+                            '<div id="{{id}}-container" class="file-row file-row-narrow">' +
                                 '<span class="file-info">' +
                                     '<span class="file-info-name">{{name}}</span>' +
                                     ' ' +
-                                    '<span class="file-info-size">({{size}})</span>' +
+                                    '<span class="file-info-size">{{size}}</span>' +
                                 '</span>' +
                                 '<span class="progress-text"></span>' +
                                 '<div class="clear"></div>' +
                             '</div>' +
-                        '</div>' +
-                            '<div class="no-display" id="[[idName]]-template-progress">' +
-                            '{{percent}}% {{uploaded}} / {{total}}' +
-                            '</div>';
+                        '</div>';
 
 var fileListTemplate = '<span class="file-info">' +
                             '<span class="file-info-name">{{name}}</span>' +
@@ -88,7 +85,7 @@ var Downloadable = {
     massUploadByType : function(type){
         try {
             this.uploaderObj.get(type).each(function(item){
-                container = item.value.container.up('tr');
+                var container = item.value.elements.container.up('tr');
                 if (container.visible() && !container.hasClassName('no-display')) {
                     item.value.upload();
                 } else {
@@ -141,10 +138,11 @@ Downloadable.FileUploader.prototype = {
                ? this.fileValue.toJSON()
                : Object.toJSON(this.fileValue);
         }
+        var uploaderConfig = (Object.isString(this.config) && this.config.evalJSON()) || this.config;
         Downloadable.setUploaderObj(
             this.type,
             this.key,
-            new Flex.Uploader(this.idName, '<?php echo $this->getSkinUrl('media/uploaderSingle.swf') ?>', this.config)
+            new Uploader(uploaderConfig)
         );
         if (varienGlobalEvents) {
             varienGlobalEvents.attachEventHandler('tabChangeBefore', Downloadable.getUploaderObj(type, key).onContainerHideBefore);
@@ -167,16 +165,48 @@ Downloadable.FileList.prototype = {
         this.containerId  = containerId,
         this.container = $(this.containerId);
         this.uploader = uploader;
-        this.uploader.onFilesComplete = this.handleUploadComplete.bind(this);
+        document.on('uploader:fileSuccess', function(event) {
+            var memo = event.memo;
+            if(this._checkCurrentContainer(memo.containerId)) {
+                this.handleUploadComplete([{response: memo.response}]);
+                this.handleButtonsSwap();
+            }
+        }.bind(this));
+        document.on('uploader:fileError', function(event) {
+            var memo = event.memo;
+            if(this._checkCurrentContainer(memo.containerId)) {
+                this.handleButtonsSwap();
+            }
+        }.bind(this));
+        document.on('upload:simulateDelete', this.handleFileRemoveAll.bind(this));
+        document.on('uploader:simulateNewUpload', this.handleFileNew.bind(this));
         this.file = this.getElement('save').value.evalJSON();
         this.listTemplate = new Template(this.fileListTemplate, this.templatePattern);
         this.updateFiles();
         this.uploader.onFileRemoveAll = this.handleFileRemoveAll.bind(this);
         this.uploader.onFileSelect = this.handleFileSelect.bind(this);
     },
-    handleFileRemoveAll: function(fileId) {
-        $(this.containerId+'-new').hide();
-        $(this.containerId+'-old').show();
+
+    _checkCurrentContainer: function (child) {
+        return $(this.containerId).down('#' + child);
+    },
+
+    handleFileRemoveAll: function(e) {
+        if(e.memo && this._checkCurrentContainer(e.memo.containerId)) {
+            $(this.containerId+'-new').hide();
+            $(this.containerId+'-old').show();
+            this.handleButtonsSwap();
+        }
+    },
+    handleFileNew: function (e) {
+        if(e.memo && this._checkCurrentContainer(e.memo.containerId)) {
+            $(this.containerId + '-new').show();
+            $(this.containerId + '-old').hide();
+            this.handleButtonsSwap();
+        }
+    },
+    handleButtonsSwap: function () {
+        $$(['#' + this.containerId+'-browse', '#'+this.containerId+'-delete']).invoke('toggle');
     },
     handleFileSelect: function() {
         $(this.containerId+'_type').checked = true;
@@ -204,7 +234,6 @@ Downloadable.FileList.prototype = {
            newFile.size = response.size;
            newFile.status = 'new';
            this.file[0] = newFile;
-           this.uploader.removeFile(item.id);
         }.bind(this));
         this.updateFiles();
     },
diff --git app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
index cd4cd81..55fdfe4 100644
--- app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
@@ -28,6 +28,7 @@
 
 /**
  * @see Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Links
+ * @var $this Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Links
  */
 ?>
 <?php $_product = $this->getProduct()?>
@@ -137,17 +138,14 @@ var linkTemplate = '<tr>'+
     '</td>'+
     '<td>'+
         '<div class="files">'+
-            '<div class="row">'+
-                '<label for="downloadable_link_{{id}}_sample_file_type"><input type="radio" class="radio" id="downloadable_link_{{id}}_sample_file_type" name="downloadable[link][{{id}}][sample][type]" value="file"{{sample_file_checked}} /> File:</label>'+
+            '<div class="row a-right">'+
+                '<label for="downloadable_link_{{id}}_sample_file_type" class="a-left"><input type="radio" class="radio" id="downloadable_link_{{id}}_sample_file_type" name="downloadable[link][{{id}}][sample][type]" value="file"{{sample_file_checked}} /> File:</label>'+
                 '<input type="hidden" id="downloadable_link_{{id}}_sample_file_save" name="downloadable[link][{{id}}][sample][file]" value="{{sample_file_save}}" />'+
-                '<div id="downloadable_link_{{id}}_sample_file" class="uploader">'+
+                '<?php echo $this->getBrowseButtonHtml('sample_'); ?>'+
+                '<?php echo $this->getDeleteButtonHtml('sample_'); ?>'+
+                '<div id="downloadable_link_{{id}}_sample_file" class="uploader a-left">'+
                     '<div id="downloadable_link_{{id}}_sample_file-old" class="file-row-info"></div>'+
                     '<div id="downloadable_link_{{id}}_sample_file-new" class="file-row-info"></div>'+
-                    '<div class="buttons">'+
-                        '<div id="downloadable_link_{{id}}_sample_file-install-flash" style="display:none">'+
-                            '<?php echo $this->jsQuoteEscape(Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/')) ?>'+
-                        '</div>'+
-                    '</div>'+
                     '<div class="clear"></div>'+
                 '</div>'+
             '</div>'+
@@ -161,17 +159,14 @@ var linkTemplate = '<tr>'+
     '</td>'+
     '<td>'+
         '<div class="files">'+
-            '<div class="row">'+
-                '<label for="downloadable_link_{{id}}_file_type"><input type="radio" class="radio validate-one-required-by-name" id="downloadable_link_{{id}}_file_type" name="downloadable[link][{{id}}][type]" value="file"{{file_checked}} /> File:</label>'+
+            '<div class="row a-right">'+
+                '<label for="downloadable_link_{{id}}_file_type" class="a-left"><input type="radio" class="radio validate-one-required-by-name" id="downloadable_link_{{id}}_file_type" name="downloadable[link][{{id}}][type]" value="file"{{file_checked}} /> File:</label>'+
             '<input type="hidden" class="validate-downloadable-file" id="downloadable_link_{{id}}_file_save" name="downloadable[link][{{id}}][file]" value="{{file_save}}" />'+
-                '<div id="downloadable_link_{{id}}_file" class="uploader">'+
+                '<?php echo $this->getBrowseButtonHtml(); ?>'+
+                '<?php echo $this->getDeleteButtonHtml(); ?>'+
+                '<div id="downloadable_link_{{id}}_file" class="uploader a-left">'+
                     '<div id="downloadable_link_{{id}}_file-old" class="file-row-info"></div>'+
                     '<div id="downloadable_link_{{id}}_file-new" class="file-row-info new-file"></div>'+
-                    '<div class="buttons">'+
-                        '<div id="downloadable_link_{{id}}_file-install-flash" style="display:none">'+
-                            '<?php echo $this->jsQuoteEscape(Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/')) ?>'+
-                        '</div>'+
-                    '</div>'+
                     '<div class="clear"></div>'+
                 '</div>'+
             '</div>'+
@@ -282,6 +277,9 @@ var linkItems = {
         if (!data.sample_file_save) {
             data.sample_file_save = [];
         }
+        var UploaderConfigLinkSamples = <?php echo $this->getConfigJson('link_samples') ?>.replace(
+            new RegExp('<?php echo $this->getId(); ?>', 'g'),
+            'downloadable_link_'+data.id+'_sample_file');
 
         // link sample file
         new Downloadable.FileUploader(
@@ -291,8 +289,12 @@ var linkItems = {
             'downloadable[link]['+data.id+'][sample]',
             data.sample_file_save,
             'downloadable_link_'+data.id+'_sample_file',
-            <?php echo $this->getConfigJson('link_samples') ?>
+            UploaderConfigLinkSamples
         );
+
+        var UploaderConfigLink = <?php echo $this->getConfigJson() ?>.replace(
+            new RegExp('<?php echo $this->getId(); ?>', 'g'),
+            'downloadable_link_'+data.id+'_file');
         // link file
         new Downloadable.FileUploader(
             'links',
@@ -301,7 +303,7 @@ var linkItems = {
             'downloadable[link]['+data.id+']',
             data.file_save,
             'downloadable_link_'+data.id+'_file',
-            <?php echo $this->getConfigJson() ?>
+            UploaderConfigLink
         );
 
         linkFile = $('downloadable_link_'+data.id+'_file_type');
diff --git app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/samples.phtml app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/samples.phtml
index e84f73f..750f824 100644
--- app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/samples.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/samples.phtml
@@ -27,6 +27,7 @@
 <?php
 /**
  * @see Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Samples
+ * @var $this Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Samples
  */
 ?>
 
@@ -89,17 +90,14 @@ var sampleTemplate = '<tr>'+
                         '</td>'+
                         '<td>'+
                             '<div class="files-wide">'+
-                                '<div class="row">'+
-                                    '<label for="downloadable_sample_{{id}}_file_type"><input type="radio" class="radio validate-one-required-by-name" id="downloadable_sample_{{id}}_file_type" name="downloadable[sample][{{id}}][type]" value="file"{{file_checked}} /> File:</label>'+
+                                '<div class="row a-right">'+
+                                    '<label for="downloadable_sample_{{id}}_file_type" class="a-left"><input type="radio" class="radio validate-one-required-by-name" id="downloadable_sample_{{id}}_file_type" name="downloadable[sample][{{id}}][type]" value="file"{{file_checked}} /> File:</label>'+
                                     '<input type="hidden" class="validate-downloadable-file" id="downloadable_sample_{{id}}_file_save" name="downloadable[sample][{{id}}][file]" value="{{file_save}}" />'+
-                                    '<div id="downloadable_sample_{{id}}_file" class="uploader">'+
+                                    '<?php echo $this->getBrowseButtonHtml(); ?>'+
+                                    '<?php echo $this->getDeleteButtonHtml(); ?>'+
+                                    '<div id="downloadable_sample_{{id}}_file" class="uploader a-left">' +
                                         '<div id="downloadable_sample_{{id}}_file-old" class="file-row-info"></div>'+
                                         '<div id="downloadable_sample_{{id}}_file-new" class="file-row-info new-file"></div>'+
-                                        '<div class="buttons">'+
-                                            '<div id="downloadable_sample_{{id}}_file-install-flash" style="display:none">'+
-                                                '<?php echo $this->jsQuoteEscape(Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/')) ?>'+
-                                            '</div>'+
-                                        '</div>'+
                                         '<div class="clear"></div>'+
                                     '</div>'+
                                 '</div>'+
@@ -161,6 +159,10 @@ var sampleItems = {
 
         sampleUrl = $('downloadable_sample_'+data.id+'_url_type');
 
+        var UploaderConfig = <?php echo $this->getConfigJson() ?>.replace(
+            new RegExp('<?php echo $this->getId(); ?>', 'g'),
+            'downloadable_sample_'+data.id+'_file');
+
         if (!data.file_save) {
             data.file_save = [];
         }
@@ -171,7 +173,7 @@ var sampleItems = {
             'downloadable[sample]['+data.id+']',
             data.file_save,
             'downloadable_sample_'+data.id+'_file',
-            <?php echo $this->getConfigJson() ?>
+            UploaderConfig
         );
         sampleUrl.advaiceContainer = 'downloadable_sample_'+data.id+'_container';
         sampleFile = $('downloadable_sample_'+data.id+'_file_type');
diff --git app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml
index 9e99f72..ca22715 100644
--- app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml
+++ app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml
@@ -66,7 +66,7 @@
                 <td class="label"><label><?php  echo $this->helper('enterprise_invitation')->__('Email'); ?><?php if ($this->canEditMessage()): ?><span class="required">*</span><?php endif; ?></label></td>
                 <td>
                 <?php if ($this->canEditMessage()): ?>
-                    <input type="text" class="required-entry input-text validate-email" name="email" value="<?php echo $this->getInvitation()->getEmail() ?>" />
+                    <input type="text" class="required-entry input-text validate-email" name="email" value="<?php echo $this->escapeHtml($this->getInvitation()->getEmail()) ?>" />
                 <?php else: ?>
                     <strong><?php echo $this->htmlEscape($this->getInvitation()->getEmail()) ?></strong>
                 <?php endif; ?>
diff --git app/design/adminhtml/default/default/template/media/uploader.phtml app/design/adminhtml/default/default/template/media/uploader.phtml
index 6f601e0..0617c16 100644
--- app/design/adminhtml/default/default/template/media/uploader.phtml
+++ app/design/adminhtml/default/default/template/media/uploader.phtml
@@ -26,48 +26,30 @@
 ?>
 <?php
 /**
- * @see Mage_Adminhtml_Block_Media_Uploader
+ * @var $this Mage_Uploader_Block_Multiple|Mage_Uploader_Block_Single
  */
 ?>
-
-<?php echo $this->helper('adminhtml/js')->includeScript('lib/flex.js') ?>
-<?php echo $this->helper('adminhtml/js')->includeScript('mage/adminhtml/flexuploader.js') ?>
-<?php echo $this->helper('adminhtml/js')->includeScript('lib/FABridge.js') ?>
-
 <div id="<?php echo $this->getHtmlId() ?>" class="uploader">
-    <div class="buttons">
-        <?php /* buttons included in flex object */ ?>
-        <?php  /*echo $this->getBrowseButtonHtml()*/  ?>
-        <?php  /*echo $this->getUploadButtonHtml()*/  ?>
-        <div id="<?php echo $this->getHtmlId() ?>-install-flash" style="display:none">
-            <?php echo Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/') ?>
-        </div>
+    <div class="buttons a-right">
+        <?php echo $this->getBrowseButtonHtml(); ?>
+        <?php echo $this->getUploadButtonHtml(); ?>
     </div>
-    <div class="clear"></div>
-    <div class="no-display" id="<?php echo $this->getHtmlId() ?>-template">
-        <div id="{{id}}" class="file-row">
-        <span class="file-info">{{name}} ({{size}})</span>
+</div>
+<div class="no-display" id="<?php echo $this->getElementId('template') ?>">
+    <div id="{{id}}-container" class="file-row">
+        <span class="file-info">{{name}} {{size}}</span>
         <span class="delete-button"><?php echo $this->getDeleteButtonHtml() ?></span>
         <span class="progress-text"></span>
         <div class="clear"></div>
-        </div>
-    </div>
-    <div class="no-display" id="<?php echo $this->getHtmlId() ?>-template-progress">
-        {{percent}}% {{uploaded}} / {{total}}
     </div>
 </div>
-
 <script type="text/javascript">
-//<![CDATA[
-
-var maxUploadFileSizeInBytes = <?php echo $this->getDataMaxSizeInBytes() ?>;
-var maxUploadFileSize = '<?php echo $this->getDataMaxSize() ?>';
-
-<?php echo $this->getJsObjectName() ?> = new Flex.Uploader('<?php echo $this->getHtmlId() ?>', '<?php echo $this->getUploaderUrl('media/uploader.swf') ?>', <?php echo $this->getConfigJson() ?>);
-
-if (varienGlobalEvents) {
-    varienGlobalEvents.attachEventHandler('tabChangeBefore', <?php echo $this->getJsObjectName() ?>.onContainerHideBefore);
-}
+    (function() {
+        var uploader = new Uploader(<?php echo $this->getJsonConfig(); ?>);
 
-//]]>
+        if (varienGlobalEvents) {
+            varienGlobalEvents.attachEventHandler('tabChangeBefore', uploader.onContainerHideBefore);
+        }
+    })();
 </script>
+<?php echo $this->getChildHtml('additional_scripts'); ?>
diff --git app/design/frontend/base/default/template/catalog/product/view.phtml app/design/frontend/base/default/template/catalog/product/view.phtml
index b0efa7c..4c018c3 100644
--- app/design/frontend/base/default/template/catalog/product/view.phtml
+++ app/design/frontend/base/default/template/catalog/product/view.phtml
@@ -40,6 +40,7 @@
 <div class="product-view">
     <div class="product-essential">
     <form action="<?php echo $this->getSubmitUrl($_product) ?>" method="post" id="product_addtocart_form"<?php if($_product->getOptions()): ?> enctype="multipart/form-data"<?php endif; ?>>
+        <?php echo $this->getBlockHtml('formkey') ?>
         <div class="no-display">
             <input type="hidden" name="product" value="<?php echo $_product->getId() ?>" />
             <input type="hidden" name="related_product" id="related-products-field" value="" />
diff --git app/design/frontend/base/default/template/checkout/cart.phtml app/design/frontend/base/default/template/checkout/cart.phtml
index a622cbf..8ffcd7b 100644
--- app/design/frontend/base/default/template/checkout/cart.phtml
+++ app/design/frontend/base/default/template/checkout/cart.phtml
@@ -47,6 +47,7 @@
     <?php echo $this->getMessagesBlock()->getGroupedHtml() ?>
     <?php echo $this->getChildHtml('form_before') ?>
     <form action="<?php echo $this->getUrl('checkout/cart/updatePost') ?>" method="post">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <fieldset>
             <table id="shopping-cart-table" class="data-table cart-table">
                 <col width="1" />
diff --git app/design/frontend/base/default/template/checkout/onepage/review/info.phtml app/design/frontend/base/default/template/checkout/onepage/review/info.phtml
index da8ee98..5cc7170 100644
--- app/design/frontend/base/default/template/checkout/onepage/review/info.phtml
+++ app/design/frontend/base/default/template/checkout/onepage/review/info.phtml
@@ -78,7 +78,7 @@
     </div>
     <script type="text/javascript">
     //<![CDATA[
-        review = new Review('<?php echo $this->getUrl('checkout/onepage/saveOrder') ?>', '<?php echo $this->getUrl('checkout/onepage/success') ?>', $('checkout-agreements'));
+        review = new Review('<?php echo $this->getUrl('checkout/onepage/saveOrder', array('form_key' => Mage::getSingleton('core/session')->getFormKey())) ?>', '<?php echo $this->getUrl('checkout/onepage/success') ?>', $('checkout-agreements'));
     //]]>
     </script>
 </div>
diff --git app/design/frontend/base/default/template/customer/form/login.phtml app/design/frontend/base/default/template/customer/form/login.phtml
index e7f2e64..2d5435d 100644
--- app/design/frontend/base/default/template/customer/form/login.phtml
+++ app/design/frontend/base/default/template/customer/form/login.phtml
@@ -39,6 +39,7 @@
     <?php /* Extensions placeholder */ ?>
     <?php echo $this->getChildHtml('customer.form.login.extra')?>
     <form action="<?php echo $this->getPostActionUrl() ?>" method="post" id="login-form">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <div class="col2-set">
             <div class="col-1 new-users">
                 <div class="content">
diff --git app/design/frontend/base/default/template/persistent/customer/form/login.phtml app/design/frontend/base/default/template/persistent/customer/form/login.phtml
index 7a21f7b..71d4321 100644
--- app/design/frontend/base/default/template/persistent/customer/form/login.phtml
+++ app/design/frontend/base/default/template/persistent/customer/form/login.phtml
@@ -38,6 +38,7 @@
     </div>
     <?php echo $this->getMessagesBlock()->getGroupedHtml() ?>
     <form action="<?php echo $this->getPostActionUrl() ?>" method="post" id="login-form">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <div class="col2-set">
             <div class="col-1 new-users">
                 <div class="content">
diff --git app/design/frontend/base/default/template/review/form.phtml app/design/frontend/base/default/template/review/form.phtml
index aaab6e5..34378ee 100644
--- app/design/frontend/base/default/template/review/form.phtml
+++ app/design/frontend/base/default/template/review/form.phtml
@@ -28,6 +28,7 @@
     <h2><?php echo $this->__('Write Your Own Review') ?></h2>
     <?php if ($this->getAllowWriteReviewFlag()): ?>
     <form action="<?php echo $this->getAction() ?>" method="post" id="review-form">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <fieldset>
             <?php echo $this->getChildHtml('form_fields_before')?>
             <h3><?php echo $this->__("You're reviewing:"); ?> <span><?php echo $this->htmlEscape($this->getProductInfo()->getName()) ?></span></h3>
diff --git app/design/frontend/base/default/template/sales/reorder/sidebar.phtml app/design/frontend/base/default/template/sales/reorder/sidebar.phtml
index b1167fc..f762336 100644
--- app/design/frontend/base/default/template/sales/reorder/sidebar.phtml
+++ app/design/frontend/base/default/template/sales/reorder/sidebar.phtml
@@ -38,6 +38,7 @@
         <strong><span><?php echo $this->__('My Orders') ?></span></strong>
     </div>
     <form method="post" action="<?php echo $this->getFormActionUrl() ?>" id="reorder-validate-detail">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <div class="block-content">
             <p class="block-subtitle"><?php echo $this->__('Last Ordered Items') ?></p>
             <ol id="cart-sidebar-reorder">
diff --git app/design/frontend/base/default/template/tag/customer/view.phtml app/design/frontend/base/default/template/tag/customer/view.phtml
index 8d49562..4024717 100644
--- app/design/frontend/base/default/template/tag/customer/view.phtml
+++ app/design/frontend/base/default/template/tag/customer/view.phtml
@@ -52,7 +52,9 @@
             </td>
             <td>
                 <?php if($_product->isSaleable()): ?>
-                    <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getUrl('checkout/cart/add',array('product'=>$_product->getId())) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
+                    <?php $params[Mage_Core_Model_Url::FORM_KEY] = Mage::getSingleton('core/session')->getFormKey() ?>
+                    <?php $params['product'] = $_product->getId(); ?>
+                    <button type="button" title="<?php echo $this->__('Add to Cart') ?>" class="button btn-cart" onclick="setLocation('<?php echo $this->getUrl('checkout/cart/add', $params) ?>')"><span><span><?php echo $this->__('Add to Cart') ?></span></span></button>
                 <?php endif; ?>
                 <?php if ($this->helper('wishlist')->isAllow()) : ?>
                 <ul class="add-to-links">
diff --git app/design/frontend/base/default/template/wishlist/view.phtml app/design/frontend/base/default/template/wishlist/view.phtml
index 7fbff55..fbb93f8 100644
--- app/design/frontend/base/default/template/wishlist/view.phtml
+++ app/design/frontend/base/default/template/wishlist/view.phtml
@@ -52,20 +52,36 @@
             </fieldset>
         </form>
 
+        <form id="wishlist-allcart-form" action="<?php echo $this->getUrl('*/*/allcart') ?>" method="post">
+            <?php echo $this->getBlockHtml('formkey') ?>
+            <div class="no-display">
+                <input type="hidden" name="wishlist_id" id="wishlist_id" value="<?php echo $this->getWishlistInstance()->getId() ?>" />
+                <input type="hidden" name="qty" id="qty" value="" />
+            </div>
+        </form>
+
         <script type="text/javascript">
         //<![CDATA[
-        var wishlistForm = new Validation($('wishlist-view-form'));
-        function addAllWItemsToCart() {
-            var url = '<?php echo $this->getUrl('*/*/allcart', array('wishlist_id' => $this->getWishlistInstance()->getId())) ?>';
-            var separator = (url.indexOf('?') >= 0) ? '&' : '?';
-            $$('#wishlist-view-form .qty').each(
-                function (input, index) {
-                    url += separator + input.name + '=' + encodeURIComponent(input.value);
-                    separator = '&';
-                }
-            );
-            setLocation(url);
-        }
+            var wishlistForm = new Validation($('wishlist-view-form'));
+            var wishlistAllCartForm = new Validation($('wishlist-allcart-form'));
+
+            function calculateQty() {
+                var itemQtys = new Array();
+                $$('#wishlist-view-form .qty').each(
+                    function (input, index) {
+                        var idxStr = input.name;
+                        var idx = idxStr.replace( /[^\d.]/g, '' );
+                        itemQtys[idx] = input.value;
+                    }
+                );
+
+                $$('#qty')[0].value = JSON.stringify(itemQtys);
+            }
+
+            function addAllWItemsToCart() {
+                calculateQty();
+                wishlistAllCartForm.form.submit();
+            }
         //]]>
         </script>
     </div>
diff --git app/design/frontend/enterprise/default/template/bundle/catalog/product/view.phtml app/design/frontend/enterprise/default/template/bundle/catalog/product/view.phtml
index eaf7789..e3c8e44 100644
--- app/design/frontend/enterprise/default/template/bundle/catalog/product/view.phtml
+++ app/design/frontend/enterprise/default/template/bundle/catalog/product/view.phtml
@@ -116,24 +116,25 @@ $_product = $this->getProduct();
             <?php echo $this->getChildHtml('product_additional_data') ?>
         </div>
         <form action="<?php echo $this->getSubmitUrl($_product) ?>" method="post" id="product_addtocart_form"<?php if($_product->getOptions()): ?> enctype="multipart/form-data"<?php endif; ?>>
-        <div class="no-display">
-            <input type="hidden" name="product" value="<?php echo $_product->getId() ?>" />
-            <input type="hidden" name="related_product" id="related-products-field" value="" />
-        </div>
-        <?php if ($_product->isSaleable() && $this->hasOptions()): ?>
-        <div id="options-container" style="display:none">
-            <div id="customizeTitle" class="page-title title-buttons">
-                <h1><?php echo $this->__('Customize %s', $_helper->productAttribute($_product, $_product->getName(), 'name')) ?></h1>
-                <a href="#" onclick="Enterprise.Bundle.end(); return false;"><small>&lsaquo;</small> Go back to product detail</a>
+            <?php echo $this->getBlockHtml('formkey') ?>
+            <div class="no-display">
+                <input type="hidden" name="product" value="<?php echo $_product->getId() ?>" />
+                <input type="hidden" name="related_product" id="related-products-field" value="" />
+            </div>
+            <?php if ($_product->isSaleable() && $this->hasOptions()): ?>
+            <div id="options-container" style="display:none">
+                <div id="customizeTitle" class="page-title title-buttons">
+                    <h1><?php echo $this->__('Customize %s', $_helper->productAttribute($_product, $_product->getName(), 'name')) ?></h1>
+                    <a href="#" onclick="Enterprise.Bundle.end(); return false;"><small>&lsaquo;</small> Go back to product detail</a>
+                </div>
+                <?php echo $this->getChildHtml('bundleSummary') ?>
+                <?php if ($this->getChildChildHtml('container1')):?>
+                    <?php echo $this->getChildChildHtml('container1', '', true, true) ?>
+                <?php elseif ($this->getChildChildHtml('container2')):?>
+                    <?php echo $this->getChildChildHtml('container2', '', true, true) ?>
+                <?php endif;?>
             </div>
-            <?php echo $this->getChildHtml('bundleSummary') ?>
-            <?php if ($this->getChildChildHtml('container1')):?>
-                <?php echo $this->getChildChildHtml('container1', '', true, true) ?>
-            <?php elseif ($this->getChildChildHtml('container2')):?>
-                <?php echo $this->getChildChildHtml('container2', '', true, true) ?>
             <?php endif;?>
-        </div>
-        <?php endif;?>
         </form>
     </div>
 </div>
diff --git app/design/frontend/enterprise/default/template/catalog/product/view.phtml app/design/frontend/enterprise/default/template/catalog/product/view.phtml
index 0ce7d88..70fb1d0 100644
--- app/design/frontend/enterprise/default/template/catalog/product/view.phtml
+++ app/design/frontend/enterprise/default/template/catalog/product/view.phtml
@@ -39,6 +39,7 @@
 <div id="messages_product_view"><?php echo $this->getMessagesBlock()->setEscapeMessageFlag(true)->toHtml() ?></div>
 <div class="product-view">
     <form action="<?php echo $this->getSubmitUrl($_product) ?>" method="post" id="product_addtocart_form"<?php if($_product->getOptions()): ?> enctype="multipart/form-data"<?php endif; ?>>
+        <?php echo $this->getBlockHtml('formkey') ?>
         <div class="no-display">
             <input type="hidden" name="product" value="<?php echo $_product->getId() ?>" />
             <input type="hidden" name="related_product" id="related-products-field" value="" />
diff --git app/design/frontend/enterprise/default/template/checkout/cart.phtml app/design/frontend/enterprise/default/template/checkout/cart.phtml
index cac1a71..4c914dc 100644
--- app/design/frontend/enterprise/default/template/checkout/cart.phtml
+++ app/design/frontend/enterprise/default/template/checkout/cart.phtml
@@ -47,6 +47,7 @@
     <?php echo $this->getMessagesBlock()->getGroupedHtml() ?>
     <?php echo $this->getChildHtml('form_before') ?>
     <form action="<?php echo $this->getUrl('checkout/cart/updatePost') ?>" method="post">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <fieldset>
             <table id="shopping-cart-table" class="data-table cart-table">
                 <col width="1" />
diff --git app/design/frontend/enterprise/default/template/checkout/cart/sku/failed.phtml app/design/frontend/enterprise/default/template/checkout/cart/sku/failed.phtml
index 3359ccd..695b6d9 100644
--- app/design/frontend/enterprise/default/template/checkout/cart/sku/failed.phtml
+++ app/design/frontend/enterprise/default/template/checkout/cart/sku/failed.phtml
@@ -33,6 +33,7 @@
 <div class="failed-products">
     <h2 class="sub-title"><?php echo $this->__('Products Requiring Attention') ?></h2>
     <form action="<?php echo $this->getFormActionUrl() ?>" method="post">
+        <?php echo $this->getBlockHtml('formkey') ?>
         <fieldset>
             <table id="failed-products-table" class="data-table cart-table">
                 <col width="1" />
diff --git app/design/frontend/enterprise/default/template/checkout/widget/sku.phtml app/design/frontend/enterprise/default/template/checkout/widget/sku.phtml
index 0d5929b..6695448 100644
--- app/design/frontend/enterprise/default/template/checkout/widget/sku.phtml
+++ app/design/frontend/enterprise/default/template/checkout/widget/sku.phtml
@@ -43,6 +43,7 @@ $qtyValidationClasses = 'required-entry validate-number validate-greater-than-ze
         </div>
         <?php endif ?>
         <form id="<?php echo $skuFormId; ?>" action="<?php echo $this->getFormAction(); ?>" method="post" <?php if ($this->getIsMultipart()): ?> enctype="multipart/form-data"<?php endif; ?>>
+            <?php echo $this->getBlockHtml('formkey'); ?>
             <div class="block-content">
                 <table id="items-table<?php echo $uniqueSuffix; ?>" class="sku-table data-table" cellspacing="0" cellpadding="0">
                     <colgroup>
diff --git app/design/frontend/enterprise/default/template/customer/form/login.phtml app/design/frontend/enterprise/default/template/customer/form/login.phtml
index 812cc28..c543f46 100644
--- app/design/frontend/enterprise/default/template/customer/form/login.phtml
+++ app/design/frontend/enterprise/default/template/customer/form/login.phtml
@@ -43,6 +43,7 @@
     <?php /* Extensions placeholder */ ?>
     <?php echo $this->getChildHtml('customer.form.login.extra')?>
     <form action="<?php echo $this->getPostActionUrl() ?>" method="post" id="login-form">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <div class="fieldset">
             <div class="col2-set">
                 <div class="col-1 registered-users">
diff --git app/design/frontend/enterprise/default/template/giftregistry/view/items.phtml app/design/frontend/enterprise/default/template/giftregistry/view/items.phtml
index 4fbb5ac..20b6efb 100644
--- app/design/frontend/enterprise/default/template/giftregistry/view/items.phtml
+++ app/design/frontend/enterprise/default/template/giftregistry/view/items.phtml
@@ -36,6 +36,7 @@
 ?>
 <h2 class="subtitle"><?php echo $this->__('Gift Registry Items') ?></h2>
 <form action="<?php echo $this->getActionUrl() ?>" method="post">
+    <?php echo $this->getBlockHtml('formkey') ?>
     <fieldset>
         <table id="shopping-cart-table" class="data-table cart-table">
             <col width="1" />
diff --git app/design/frontend/enterprise/default/template/persistent/customer/form/login.phtml app/design/frontend/enterprise/default/template/persistent/customer/form/login.phtml
index f60a518..50006e4 100644
--- app/design/frontend/enterprise/default/template/persistent/customer/form/login.phtml
+++ app/design/frontend/enterprise/default/template/persistent/customer/form/login.phtml
@@ -42,6 +42,7 @@
     </div>
     <?php echo $this->getMessagesBlock()->getGroupedHtml() ?>
     <form action="<?php echo $this->getPostActionUrl() ?>" method="post" id="login-form">
+        <?php echo $this->getBlockHtml('formkey'); ?>
         <div class="fieldset">
             <div class="col2-set">
                 <div class="col-1 registered-users">
diff --git app/design/frontend/enterprise/default/template/review/form.phtml app/design/frontend/enterprise/default/template/review/form.phtml
index e616da8..0df4c46 100644
--- app/design/frontend/enterprise/default/template/review/form.phtml
+++ app/design/frontend/enterprise/default/template/review/form.phtml
@@ -29,6 +29,7 @@
 </div>
 <?php if ($this->getAllowWriteReviewFlag()): ?>
 <form action="<?php echo $this->getAction() ?>" method="post" id="review-form">
+    <?php echo $this->getBlockHtml('formkey'); ?>
     <?php echo $this->getChildHtml('form_fields_before')?>
     <div class="box-content">
         <h3 class="product-name"><?php echo $this->__("You're reviewing:"); ?> <span><?php echo $this->htmlEscape($this->getProductInfo()->getName()) ?></span></h3>
diff --git app/design/frontend/enterprise/default/template/wishlist/info.phtml app/design/frontend/enterprise/default/template/wishlist/info.phtml
index 7293b52..08619c7 100644
--- app/design/frontend/enterprise/default/template/wishlist/info.phtml
+++ app/design/frontend/enterprise/default/template/wishlist/info.phtml
@@ -59,6 +59,7 @@
 
 <h2 class="subtitle"><?php echo $this->__('Wishlist Items') ?></h2>
 <form method="post" action="<?php echo $this->getToCartUrl();?>" id="wishlist-info-form">
+    <?php echo $this->getBlockHtml('formkey') ?>
     <?php $this->getChild('items')->setItems($this->getWishlistItems()); ?>
     <?php echo $this->getChildHtml('items');?>
     <?php if (count($wishlistItems) && $this->isSaleable()): ?>
diff --git app/design/frontend/enterprise/iphone/template/catalog/product/view.phtml app/design/frontend/enterprise/iphone/template/catalog/product/view.phtml
index 44b677f..0faf416 100644
--- app/design/frontend/enterprise/iphone/template/catalog/product/view.phtml
+++ app/design/frontend/enterprise/iphone/template/catalog/product/view.phtml
@@ -39,6 +39,7 @@
 <div id="messages_product_view"><?php echo $this->getMessagesBlock()->setEscapeMessageFlag(true)->toHtml() ?></div>
 <div class="product-view">
     <form action="<?php echo $this->getSubmitUrl($_product) ?>" method="post" id="product_addtocart_form"<?php if($_product->getOptions()): ?> enctype="multipart/form-data"<?php endif; ?>>
+        <?php echo $this->getBlockHtml('formkey') ?>
         <div class="no-display">
             <input type="hidden" name="product" value="<?php echo $_product->getId() ?>" />
             <input type="hidden" name="related_product" id="related-products-field" value="" />
diff --git app/design/frontend/enterprise/iphone/template/checkout/cart.phtml app/design/frontend/enterprise/iphone/template/checkout/cart.phtml
index 3bc2190..7a9113d 100644
--- app/design/frontend/enterprise/iphone/template/checkout/cart.phtml
+++ app/design/frontend/enterprise/iphone/template/checkout/cart.phtml
@@ -45,6 +45,7 @@
         </ul>
     <?php endif; ?>
     <form action="<?php echo $this->getUrl('checkout/cart/updatePost') ?>" method="post">
+        <?php echo $this->getBlockHtml('formkey') ?>
         <fieldset>
             <table id="shopping-cart-table" class="data-table cart-table">
                 <tfoot>
diff --git app/design/frontend/enterprise/iphone/template/checkout/onepage/review/info.phtml app/design/frontend/enterprise/iphone/template/checkout/onepage/review/info.phtml
index 1092c70..a4b9be1 100644
--- app/design/frontend/enterprise/iphone/template/checkout/onepage/review/info.phtml
+++ app/design/frontend/enterprise/iphone/template/checkout/onepage/review/info.phtml
@@ -56,7 +56,7 @@
     </div>
     <script type="text/javascript">
     //<![CDATA[
-        review = new Review('<?php echo $this->getUrl('checkout/onepage/saveOrder') ?>', '<?php echo $this->getUrl('checkout/onepage/success') ?>', $('checkout-agreements'));
+        review = new Review('<?php echo $this->getUrl('checkout/onepage/saveOrder', array('form_key' => Mage::getSingleton('core/session')->getFormKey())) ?>', '<?php echo $this->getUrl('checkout/onepage/success') ?>', $('checkout-agreements'));
     //]]>
     </script>
 </div>
diff --git app/design/frontend/enterprise/iphone/template/giftregistry/view/items.phtml app/design/frontend/enterprise/iphone/template/giftregistry/view/items.phtml
index d57bb88..aae0092 100644
--- app/design/frontend/enterprise/iphone/template/giftregistry/view/items.phtml
+++ app/design/frontend/enterprise/iphone/template/giftregistry/view/items.phtml
@@ -36,6 +36,7 @@
 ?>
 <!--<h2 class="subtitle"><?php echo $this->__('Gift Registry Items') ?></h2>-->
 <form action="<?php echo $this->getActionUrl() ?>" method="post">
+    <?php echo $this->getBlockHtml('formkey') ?>
     <fieldset>
         <ul class="list">
             <?php foreach($this->getItems() as $_item): ?>
diff --git app/design/frontend/enterprise/iphone/template/wishlist/view.phtml app/design/frontend/enterprise/iphone/template/wishlist/view.phtml
index cdbf474..0c35dd4 100644
--- app/design/frontend/enterprise/iphone/template/wishlist/view.phtml
+++ app/design/frontend/enterprise/iphone/template/wishlist/view.phtml
@@ -48,21 +48,37 @@
             </fieldset>
         </form>
 
+        <form id="wishlist-allcart-form" action="<?php echo $this->getUrl('*/*/allcart') ?>" method="post">
+            <?php echo $this->getBlockHtml('formkey') ?>
+            <div class="no-display">
+                <input type="hidden" name="wishlist_id" id="wishlist_id" value="<?php echo $this->getWishlistInstance()->getId() ?>" />
+                <input type="hidden" name="qty" id="qty" value="" />
+            </div>
+        </form>
+
         <script type="text/javascript">
-        //<![CDATA[
-        var wishlistForm = new Validation($('wishlist-view-form'));
-        function addAllWItemsToCart() {
-            var url = '<?php echo $this->getUrl('*/*/allcart', array('wishlist_id' => $this->getWishlistInstance()->getId())) ?>';
-            var separator = (url.indexOf('?') >= 0) ? '&' : '?';
-            $$('#wishlist-view-form .qty').each(
-                function (input, index) {
-                    url += separator + input.name + '=' + encodeURIComponent(input.value);
-                    separator = '&';
-                }
-            );
-            setLocation(url);
-        }
-        //]]>
+            //<![CDATA[
+            var wishlistForm = new Validation($('wishlist-view-form'));
+            var wishlistAllCartForm = new Validation($('wishlist-allcart-form'));
+
+            function calculateQty() {
+                var itemQtys = new Array();
+                $$('#wishlist-view-form .qty').each(
+                    function (input, index) {
+                        var idxStr = input.name;
+                        var idx = idxStr.replace( /[^\d.]/g, '' );
+                        itemQtys[idx] = input.value;
+                    }
+                );
+
+                $$('#qty')[0].value = JSON.stringify(itemQtys);
+            }
+
+            function addAllWItemsToCart() {
+                calculateQty();
+                wishlistAllCartForm.form.submit();
+            }
+            //]]>
         </script>
     </div>
     <?php echo $this->getChildHtml('bottom'); ?>
diff --git app/etc/modules/Mage_All.xml app/etc/modules/Mage_All.xml
index 6469942..5471e89 100644
--- app/etc/modules/Mage_All.xml
+++ app/etc/modules/Mage_All.xml
@@ -275,7 +275,7 @@
             <active>true</active>
             <codePool>core</codePool>
             <depends>
-                <Mage_Core/>
+                <Mage_Uploader/>
             </depends>
         </Mage_Cms>
         <Mage_Reports>
@@ -397,5 +397,12 @@
                 <Mage_Core/>
             </depends>
         </Mage_Index>
+        <Mage_Uploader>
+            <active>true</active>
+            <codePool>core</codePool>
+            <depends>
+                <Mage_Core/>
+            </depends>
+        </Mage_Uploader>
     </modules>
 </config>
diff --git app/locale/en_US/Mage_Media.csv app/locale/en_US/Mage_Media.csv
index 110331b..504a44a 100644
--- app/locale/en_US/Mage_Media.csv
+++ app/locale/en_US/Mage_Media.csv
@@ -1,3 +1,2 @@
 "An error occurred while creating the image.","An error occurred while creating the image."
 "The image does not exist or is invalid.","The image does not exist or is invalid."
-"This content requires last version of Adobe Flash Player. <a href=""%s"">Get Flash</a>","This content requires last version of Adobe Flash Player. <a href=""%s"">Get Flash</a>"
diff --git app/locale/en_US/Mage_Uploader.csv app/locale/en_US/Mage_Uploader.csv
new file mode 100644
index 0000000..c246b24
--- /dev/null
+++ app/locale/en_US/Mage_Uploader.csv
@@ -0,0 +1,8 @@
+"Browse Files...","Browse Files..."
+"Upload Files","Upload Files"
+"Remove", "Remove"
+"There are files that were selected but not uploaded yet. After switching to another tab your selections will be lost. Do you wish to continue ?", "There are files that were selected but not uploaded yet. After switching to another tab your selections will be lost. Do you wish to continue ?"
+"Maximum allowed file size for upload is","Maximum allowed file size for upload is"
+"Please check your server PHP settings.","Please check your server PHP settings."
+"Uploading...","Uploading..."
+"Complete","Complete"
\ No newline at end of file
diff --git downloader/Maged/Controller.php downloader/Maged/Controller.php
index f52945e..b2ea185 100755
--- downloader/Maged/Controller.php
+++ downloader/Maged/Controller.php
@@ -367,6 +367,11 @@ final class Maged_Controller
      */
     public function connectInstallPackageUploadAction()
     {
+        if (!$this->_validateFormKey()) {
+            echo "No file was uploaded";
+            return;
+        }
+
         if (!$_FILES) {
             echo "No file was uploaded";
             return;
@@ -1090,4 +1095,27 @@ final class Maged_Controller
 
         return $messagesMap[$type];
     }
+
+    /**
+     * Validate Form Key
+     *
+     * @return bool
+     */
+    protected function _validateFormKey()
+    {
+        if (!($formKey = $_REQUEST['form_key']) || $formKey != $this->session()->getFormKey()) {
+            return false;
+        }
+        return true;
+    }
+
+    /**
+     * Retrieve Session Form Key
+     *
+     * @return string
+     */
+    public function getFormKey()
+    {
+        return $this->session()->getFormKey();
+    }
 }
diff --git downloader/Maged/Model/Session.php downloader/Maged/Model/Session.php
index ea0cfb7..4b59568 100644
--- downloader/Maged/Model/Session.php
+++ downloader/Maged/Model/Session.php
@@ -221,4 +221,17 @@ class Maged_Model_Session extends Maged_Model
         }
         return Mage::getSingleton('adminhtml/url')->getUrl('adminhtml');
     }
+
+    /**
+     * Retrieve Session Form Key
+     *
+     * @return string A 16 bit unique key for forms
+     */
+    public function getFormKey()
+    {
+        if (!$this->get('_form_key')) {
+            $this->set('_form_key', Mage::helper('core')->getRandomString(16));
+        }
+        return $this->get('_form_key');
+    }
 }
diff --git downloader/Maged/View.php downloader/Maged/View.php
index d707f18..59a98c3 100755
--- downloader/Maged/View.php
+++ downloader/Maged/View.php
@@ -154,6 +154,16 @@ class Maged_View
     }
 
     /**
+     * Retrieve Session Form Key
+     *
+     * @return string
+     */
+    public function getFormKey()
+    {
+        return $this->controller()->getFormKey();
+    }
+
+    /**
      * Escape html entities
      *
      * @param   mixed $data
diff --git downloader/lib/Mage/HTTP/Client/Curl.php downloader/lib/Mage/HTTP/Client/Curl.php
index 5f62e95..0bb7b06 100644
--- downloader/lib/Mage/HTTP/Client/Curl.php
+++ downloader/lib/Mage/HTTP/Client/Curl.php
@@ -378,8 +378,8 @@ implements Mage_HTTP_IClient
         }
 
         $this->curlOption(CURLOPT_URL, $uri);
-        $this->curlOption(CURLOPT_SSL_VERIFYPEER, FALSE);
-        $this->curlOption(CURLOPT_SSL_VERIFYHOST, 2);
+        $this->curlOption(CURLOPT_SSL_VERIFYPEER, true);
+        $this->curlOption(CURLOPT_SSL_VERIFYHOST, 'TLSv1');
 
         // force method to POST if secured
         if ($isAuthorizationRequired) {
diff --git downloader/template/connect/packages.phtml downloader/template/connect/packages.phtml
index 94c09dd..25ffe8e 100644
--- downloader/template/connect/packages.phtml
+++ downloader/template/connect/packages.phtml
@@ -143,6 +143,7 @@ function connectPrepare(form) {
     <h4>Direct package file upload</h4>
 </div>
 <form action="<?php echo $this->url('connectInstallPackageUpload')?>" method="post" target="connect_iframe" onsubmit="onSubmit(this)" enctype="multipart/form-data">
+    <input name="form_key" type="hidden" value="<?php echo $this->getFormKey() ?>" />
     <ul class="bare-list">
         <li><span class="step-count">1</span> &nbsp; Download or build package file.</li>
         <li>
diff --git js/lib/uploader/flow.min.js js/lib/uploader/flow.min.js
new file mode 100644
index 0000000..34b888e
--- /dev/null
+++ js/lib/uploader/flow.min.js
@@ -0,0 +1,2 @@
+/*! flow.js 2.9.0 */
+!function(a,b,c){"use strict";function d(b){if(this.support=!("undefined"==typeof File||"undefined"==typeof Blob||"undefined"==typeof FileList||!Blob.prototype.slice&&!Blob.prototype.webkitSlice&&!Blob.prototype.mozSlice),this.support){this.supportDirectory=/WebKit/.test(a.navigator.userAgent),this.files=[],this.defaults={chunkSize:1048576,forceChunkSize:!1,simultaneousUploads:3,singleFile:!1,fileParameterName:"file",progressCallbacksInterval:500,speedSmoothingFactor:.1,query:{},headers:{},withCredentials:!1,preprocess:null,method:"multipart",testMethod:"GET",uploadMethod:"POST",prioritizeFirstAndLastChunk:!1,target:"/",testChunks:!0,generateUniqueIdentifier:null,maxChunkRetries:0,chunkRetryInterval:null,permanentErrors:[404,415,500,501],successStatuses:[200,201,202],onDropStopPropagation:!1},this.opts={},this.events={};var c=this;this.onDrop=function(a){c.opts.onDropStopPropagation&&a.stopPropagation(),a.preventDefault();var b=a.dataTransfer;b.items&&b.items[0]&&b.items[0].webkitGetAsEntry?c.webkitReadDataTransfer(a):c.addFiles(b.files,a)},this.preventEvent=function(a){a.preventDefault()},this.opts=d.extend({},this.defaults,b||{})}}function e(a,b){this.flowObj=a,this.file=b,this.name=b.fileName||b.name,this.size=b.size,this.relativePath=b.relativePath||b.webkitRelativePath||this.name,this.uniqueIdentifier=a.generateUniqueIdentifier(b),this.chunks=[],this.paused=!1,this.error=!1,this.averageSpeed=0,this.currentSpeed=0,this._lastProgressCallback=Date.now(),this._prevUploadedSize=0,this._prevProgress=0,this.bootstrap()}function f(a,b,c){this.flowObj=a,this.fileObj=b,this.fileObjSize=b.size,this.offset=c,this.tested=!1,this.retries=0,this.pendingRetry=!1,this.preprocessState=0,this.loaded=0,this.total=0;var d=this.flowObj.opts.chunkSize;this.startByte=this.offset*d,this.endByte=Math.min(this.fileObjSize,(this.offset+1)*d),this.xhr=null,this.fileObjSize-this.endByte<d&&!this.flowObj.opts.forceChunkSize&&(this.endByte=this.fileObjSize);var e=this;this.event=function(a,b){b=Array.prototype.slice.call(arguments),b.unshift(e),e.fileObj.chunkEvent.apply(e.fileObj,b)},this.progressHandler=function(a){a.lengthComputable&&(e.loaded=a.loaded,e.total=a.total),e.event("progress",a)},this.testHandler=function(){var a=e.status(!0);"error"===a?(e.event(a,e.message()),e.flowObj.uploadNextChunk()):"success"===a?(e.tested=!0,e.event(a,e.message()),e.flowObj.uploadNextChunk()):e.fileObj.paused||(e.tested=!0,e.send())},this.doneHandler=function(){var a=e.status();if("success"===a||"error"===a)e.event(a,e.message()),e.flowObj.uploadNextChunk();else{e.event("retry",e.message()),e.pendingRetry=!0,e.abort(),e.retries++;var b=e.flowObj.opts.chunkRetryInterval;null!==b?setTimeout(function(){e.send()},b):e.send()}}}function g(a,b){var c=a.indexOf(b);c>-1&&a.splice(c,1)}function h(a,b){return"function"==typeof a&&(b=Array.prototype.slice.call(arguments),a=a.apply(null,b.slice(1))),a}function i(a,b){setTimeout(a.bind(b),0)}function j(a){return k(arguments,function(b){b!==a&&k(b,function(b,c){a[c]=b})}),a}function k(a,b,c){if(a){var d;if("undefined"!=typeof a.length){for(d=0;d<a.length;d++)if(b.call(c,a[d],d)===!1)return}else for(d in a)if(a.hasOwnProperty(d)&&b.call(c,a[d],d)===!1)return}}var l=a.navigator.msPointerEnabled;d.prototype={on:function(a,b){a=a.toLowerCase(),this.events.hasOwnProperty(a)||(this.events[a]=[]),this.events[a].push(b)},off:function(a,b){a!==c?(a=a.toLowerCase(),b!==c?this.events.hasOwnProperty(a)&&g(this.events[a],b):delete this.events[a]):this.events={}},fire:function(a,b){b=Array.prototype.slice.call(arguments),a=a.toLowerCase();var c=!1;return this.events.hasOwnProperty(a)&&k(this.events[a],function(a){c=a.apply(this,b.slice(1))===!1||c},this),"catchall"!=a&&(b.unshift("catchAll"),c=this.fire.apply(this,b)===!1||c),!c},webkitReadDataTransfer:function(a){function b(a){g+=a.length,k(a,function(a){if(a.isFile){var e=a.fullPath;a.file(function(a){c(a,e)},d)}else a.isDirectory&&a.createReader().readEntries(b,d)}),e()}function c(a,b){a.relativePath=b.substring(1),h.push(a),e()}function d(a){throw a}function e(){0==--g&&f.addFiles(h,a)}var f=this,g=a.dataTransfer.items.length,h=[];k(a.dataTransfer.items,function(a){var f=a.webkitGetAsEntry();return f?void(f.isFile?c(a.getAsFile(),f.fullPath):f.createReader().readEntries(b,d)):void e()})},generateUniqueIdentifier:function(a){var b=this.opts.generateUniqueIdentifier;if("function"==typeof b)return b(a);var c=a.relativePath||a.webkitRelativePath||a.fileName||a.name;return a.size+"-"+c.replace(/[^0-9a-zA-Z_-]/gim,"")},uploadNextChunk:function(a){var b=!1;if(this.opts.prioritizeFirstAndLastChunk&&(k(this.files,function(a){return!a.paused&&a.chunks.length&&"pending"===a.chunks[0].status()&&0===a.chunks[0].preprocessState?(a.chunks[0].send(),b=!0,!1):!a.paused&&a.chunks.length>1&&"pending"===a.chunks[a.chunks.length-1].status()&&0===a.chunks[0].preprocessState?(a.chunks[a.chunks.length-1].send(),b=!0,!1):void 0}),b))return b;if(k(this.files,function(a){return a.paused||k(a.chunks,function(a){return"pending"===a.status()&&0===a.preprocessState?(a.send(),b=!0,!1):void 0}),b?!1:void 0}),b)return!0;var c=!1;return k(this.files,function(a){return a.isComplete()?void 0:(c=!0,!1)}),c||a||i(function(){this.fire("complete")},this),!1},assignBrowse:function(a,c,d,e){"undefined"==typeof a.length&&(a=[a]),k(a,function(a){var f;"INPUT"===a.tagName&&"file"===a.type?f=a:(f=b.createElement("input"),f.setAttribute("type","file"),j(f.style,{visibility:"hidden",position:"absolute"}),a.appendChild(f),a.addEventListener("click",function(){f.click()},!1)),this.opts.singleFile||d||f.setAttribute("multiple","multiple"),c&&f.setAttribute("webkitdirectory","webkitdirectory"),k(e,function(a,b){f.setAttribute(b,a)});var g=this;f.addEventListener("change",function(a){g.addFiles(a.target.files,a),a.target.value=""},!1)},this)},assignDrop:function(a){"undefined"==typeof a.length&&(a=[a]),k(a,function(a){a.addEventListener("dragover",this.preventEvent,!1),a.addEventListener("dragenter",this.preventEvent,!1),a.addEventListener("drop",this.onDrop,!1)},this)},unAssignDrop:function(a){"undefined"==typeof a.length&&(a=[a]),k(a,function(a){a.removeEventListener("dragover",this.preventEvent),a.removeEventListener("dragenter",this.preventEvent),a.removeEventListener("drop",this.onDrop)},this)},isUploading:function(){var a=!1;return k(this.files,function(b){return b.isUploading()?(a=!0,!1):void 0}),a},_shouldUploadNext:function(){var a=0,b=!0,c=this.opts.simultaneousUploads;return k(this.files,function(d){k(d.chunks,function(d){return"uploading"===d.status()&&(a++,a>=c)?(b=!1,!1):void 0})}),b&&a},upload:function(){var a=this._shouldUploadNext();if(a!==!1){this.fire("uploadStart");for(var b=!1,c=1;c<=this.opts.simultaneousUploads-a;c++)b=this.uploadNextChunk(!0)||b;b||i(function(){this.fire("complete")},this)}},resume:function(){k(this.files,function(a){a.resume()})},pause:function(){k(this.files,function(a){a.pause()})},cancel:function(){for(var a=this.files.length-1;a>=0;a--)this.files[a].cancel()},progress:function(){var a=0,b=0;return k(this.files,function(c){a+=c.progress()*c.size,b+=c.size}),b>0?a/b:0},addFile:function(a,b){this.addFiles([a],b)},addFiles:function(a,b){var c=[];k(a,function(a){if((!l||l&&a.size>0)&&(a.size%4096!==0||"."!==a.name&&"."!==a.fileName)&&!this.getFromUniqueIdentifier(this.generateUniqueIdentifier(a))){var d=new e(this,a);this.fire("fileAdded",d,b)&&c.push(d)}},this),this.fire("filesAdded",c,b)&&k(c,function(a){this.opts.singleFile&&this.files.length>0&&this.removeFile(this.files[0]),this.files.push(a)},this),this.fire("filesSubmitted",c,b)},removeFile:function(a){for(var b=this.files.length-1;b>=0;b--)this.files[b]===a&&(this.files.splice(b,1),a.abort())},getFromUniqueIdentifier:function(a){var b=!1;return k(this.files,function(c){c.uniqueIdentifier===a&&(b=c)}),b},getSize:function(){var a=0;return k(this.files,function(b){a+=b.size}),a},sizeUploaded:function(){var a=0;return k(this.files,function(b){a+=b.sizeUploaded()}),a},timeRemaining:function(){var a=0,b=0;return k(this.files,function(c){c.paused||c.error||(a+=c.size-c.sizeUploaded(),b+=c.averageSpeed)}),a&&!b?Number.POSITIVE_INFINITY:a||b?Math.floor(a/b):0}},e.prototype={measureSpeed:function(){var a=Date.now()-this._lastProgressCallback;if(a){var b=this.flowObj.opts.speedSmoothingFactor,c=this.sizeUploaded();this.currentSpeed=Math.max((c-this._prevUploadedSize)/a*1e3,0),this.averageSpeed=b*this.currentSpeed+(1-b)*this.averageSpeed,this._prevUploadedSize=c}},chunkEvent:function(a,b,c){switch(b){case"progress":if(Date.now()-this._lastProgressCallback<this.flowObj.opts.progressCallbacksInterval)break;this.measureSpeed(),this.flowObj.fire("fileProgress",this,a),this.flowObj.fire("progress"),this._lastProgressCallback=Date.now();break;case"error":this.error=!0,this.abort(!0),this.flowObj.fire("fileError",this,c,a),this.flowObj.fire("error",c,this,a);break;case"success":if(this.error)return;this.measureSpeed(),this.flowObj.fire("fileProgress",this,a),this.flowObj.fire("progress"),this._lastProgressCallback=Date.now(),this.isComplete()&&(this.currentSpeed=0,this.averageSpeed=0,this.flowObj.fire("fileSuccess",this,c,a));break;case"retry":this.flowObj.fire("fileRetry",this,a)}},pause:function(){this.paused=!0,this.abort()},resume:function(){this.paused=!1,this.flowObj.upload()},abort:function(a){this.currentSpeed=0,this.averageSpeed=0;var b=this.chunks;a&&(this.chunks=[]),k(b,function(a){"uploading"===a.status()&&(a.abort(),this.flowObj.uploadNextChunk())},this)},cancel:function(){this.flowObj.removeFile(this)},retry:function(){this.bootstrap(),this.flowObj.upload()},bootstrap:function(){this.abort(!0),this.error=!1,this._prevProgress=0;for(var a=this.flowObj.opts.forceChunkSize?Math.ceil:Math.floor,b=Math.max(a(this.file.size/this.flowObj.opts.chunkSize),1),c=0;b>c;c++)this.chunks.push(new f(this.flowObj,this,c))},progress:function(){if(this.error)return 1;if(1===this.chunks.length)return this._prevProgress=Math.max(this._prevProgress,this.chunks[0].progress()),this._prevProgress;var a=0;k(this.chunks,function(b){a+=b.progress()*(b.endByte-b.startByte)});var b=a/this.size;return this._prevProgress=Math.max(this._prevProgress,b>.9999?1:b),this._prevProgress},isUploading:function(){var a=!1;return k(this.chunks,function(b){return"uploading"===b.status()?(a=!0,!1):void 0}),a},isComplete:function(){var a=!1;return k(this.chunks,function(b){var c=b.status();return"pending"===c||"uploading"===c||1===b.preprocessState?(a=!0,!1):void 0}),!a},sizeUploaded:function(){var a=0;return k(this.chunks,function(b){a+=b.sizeUploaded()}),a},timeRemaining:function(){if(this.paused||this.error)return 0;var a=this.size-this.sizeUploaded();return a&&!this.averageSpeed?Number.POSITIVE_INFINITY:a||this.averageSpeed?Math.floor(a/this.averageSpeed):0},getType:function(){return this.file.type&&this.file.type.split("/")[1]},getExtension:function(){return this.name.substr((~-this.name.lastIndexOf(".")>>>0)+2).toLowerCase()}},f.prototype={getParams:function(){return{flowChunkNumber:this.offset+1,flowChunkSize:this.flowObj.opts.chunkSize,flowCurrentChunkSize:this.endByte-this.startByte,flowTotalSize:this.fileObjSize,flowIdentifier:this.fileObj.uniqueIdentifier,flowFilename:this.fileObj.name,flowRelativePath:this.fileObj.relativePath,flowTotalChunks:this.fileObj.chunks.length}},getTarget:function(a,b){return a+=a.indexOf("?")<0?"?":"&",a+b.join("&")},test:function(){this.xhr=new XMLHttpRequest,this.xhr.addEventListener("load",this.testHandler,!1),this.xhr.addEventListener("error",this.testHandler,!1);var a=h(this.flowObj.opts.testMethod,this.fileObj,this),b=this.prepareXhrRequest(a,!0);this.xhr.send(b)},preprocessFinished:function(){this.preprocessState=2,this.send()},send:function(){var a=this.flowObj.opts.preprocess;if("function"==typeof a)switch(this.preprocessState){case 0:return this.preprocessState=1,void a(this);case 1:return}if(this.flowObj.opts.testChunks&&!this.tested)return void this.test();this.loaded=0,this.total=0,this.pendingRetry=!1;var b=this.fileObj.file.slice?"slice":this.fileObj.file.mozSlice?"mozSlice":this.fileObj.file.webkitSlice?"webkitSlice":"slice",c=this.fileObj.file[b](this.startByte,this.endByte,this.fileObj.file.type);this.xhr=new XMLHttpRequest,this.xhr.upload.addEventListener("progress",this.progressHandler,!1),this.xhr.addEventListener("load",this.doneHandler,!1),this.xhr.addEventListener("error",this.doneHandler,!1);var d=h(this.flowObj.opts.uploadMethod,this.fileObj,this),e=this.prepareXhrRequest(d,!1,this.flowObj.opts.method,c);this.xhr.send(e)},abort:function(){var a=this.xhr;this.xhr=null,a&&a.abort()},status:function(a){return this.pendingRetry||1===this.preprocessState?"uploading":this.xhr?this.xhr.readyState<4?"uploading":this.flowObj.opts.successStatuses.indexOf(this.xhr.status)>-1?"success":this.flowObj.opts.permanentErrors.indexOf(this.xhr.status)>-1||!a&&this.retries>=this.flowObj.opts.maxChunkRetries?"error":(this.abort(),"pending"):"pending"},message:function(){return this.xhr?this.xhr.responseText:""},progress:function(){if(this.pendingRetry)return 0;var a=this.status();return"success"===a||"error"===a?1:"pending"===a?0:this.total>0?this.loaded/this.total:0},sizeUploaded:function(){var a=this.endByte-this.startByte;return"success"!==this.status()&&(a=this.progress()*a),a},prepareXhrRequest:function(a,b,c,d){var e=h(this.flowObj.opts.query,this.fileObj,this,b);e=j(this.getParams(),e);var f=h(this.flowObj.opts.target,this.fileObj,this,b),g=null;if("GET"===a||"octet"===c){var i=[];k(e,function(a,b){i.push([encodeURIComponent(b),encodeURIComponent(a)].join("="))}),f=this.getTarget(f,i),g=d||null}else g=new FormData,k(e,function(a,b){g.append(b,a)}),g.append(this.flowObj.opts.fileParameterName,d,this.fileObj.file.name);return this.xhr.open(a,f,!0),this.xhr.withCredentials=this.flowObj.opts.withCredentials,k(h(this.flowObj.opts.headers,this.fileObj,this,b),function(a,b){this.xhr.setRequestHeader(b,a)},this),g}},d.evalOpts=h,d.extend=j,d.each=k,d.FlowFile=e,d.FlowChunk=f,d.version="2.9.0","object"==typeof module&&module&&"object"==typeof module.exports?module.exports=d:(a.Flow=d,"function"==typeof define&&define.amd&&define("flow",[],function(){return d}))}(window,document);
\ No newline at end of file
diff --git js/lib/uploader/fusty-flow-factory.js js/lib/uploader/fusty-flow-factory.js
new file mode 100644
index 0000000..3d09bb0
--- /dev/null
+++ js/lib/uploader/fusty-flow-factory.js
@@ -0,0 +1,14 @@
+(function (Flow, FustyFlow, window) {
+  'use strict';
+
+  var fustyFlowFactory = function (opts) {
+    var flow = new Flow(opts);
+    if (flow.support) {
+      return flow;
+    }
+    return new FustyFlow(opts);
+  }
+
+  window.fustyFlowFactory = fustyFlowFactory;
+
+})(window.Flow, window.FustyFlow, window);
diff --git js/lib/uploader/fusty-flow.js js/lib/uploader/fusty-flow.js
new file mode 100644
index 0000000..4519a81
--- /dev/null
+++ js/lib/uploader/fusty-flow.js
@@ -0,0 +1,428 @@
+(function (Flow, window, document, undefined) {
+  'use strict';
+
+  var extend = Flow.extend;
+  var each = Flow.each;
+
+  function addEvent(element, type, handler) {
+    if (element.addEventListener) {
+      element.addEventListener(type, handler, false);
+    } else if (element.attachEvent) {
+      element.attachEvent("on" + type, handler);
+    } else {
+      element["on" + type] = handler;
+    }
+  }
+
+  function removeEvent(element, type, handler) {
+    if (element.removeEventListener) {
+      element.removeEventListener(type, handler, false);
+    } else if (element.detachEvent) {
+      element.detachEvent("on" + type, handler);
+    } else {
+      element["on" + type] = null;
+    }
+  }
+
+  function removeElement(element) {
+    element.parentNode.removeChild(element);
+  }
+
+  function isFunction(functionToCheck) {
+    var getType = {};
+    return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
+  }
+
+  /**
+   * Not resumable file upload library, for IE7-IE9 browsers
+   * @name FustyFlow
+   * @param [opts]
+   * @param {bool} [opts.singleFile]
+   * @param {string} [opts.fileParameterName]
+   * @param {Object|Function} [opts.query]
+   * @param {Object} [opts.headers]
+   * @param {string} [opts.target]
+   * @param {Function} [opts.generateUniqueIdentifier]
+   * @param {bool} [opts.matchJSON]
+   * @constructor
+   */
+  function FustyFlow(opts) {
+    // Shortcut of "r instanceof Flow"
+    this.support = false;
+
+    this.files = [];
+    this.events = [];
+    this.defaults = {
+      simultaneousUploads: 3,
+      fileParameterName: 'file',
+      query: {},
+      target: '/',
+      generateUniqueIdentifier: null,
+      matchJSON: false
+    };
+
+    var $ = this;
+
+    this.inputChangeEvent = function (event) {
+      var input = event.target || event.srcElement;
+      removeEvent(input, 'change', $.inputChangeEvent);
+      var newClone = input.cloneNode(false);
+      // change current input with new one
+      input.parentNode.replaceChild(newClone, input);
+      // old input will be attached to hidden form
+      $.addFile(input, event);
+      // reset new input
+      newClone.value = '';
+      addEvent(newClone, 'change', $.inputChangeEvent);
+    };
+
+    this.opts = Flow.extend({}, this.defaults, opts || {});
+  }
+
+  FustyFlow.prototype = {
+    on: Flow.prototype.on,
+    off: Flow.prototype.off,
+    fire: Flow.prototype.fire,
+    cancel: Flow.prototype.cancel,
+    assignBrowse: function (domNodes) {
+      if (typeof domNodes.length == 'undefined') {
+        domNodes = [domNodes];
+      }
+      each(domNodes, function (domNode) {
+        var input;
+        if (domNode.tagName === 'INPUT' && domNode.type === 'file') {
+          input = domNode;
+        } else {
+          input = document.createElement('input');
+          input.setAttribute('type', 'file');
+
+          extend(domNode.style, {
+            display: 'inline-block',
+            position: 'relative',
+            overflow: 'hidden',
+            verticalAlign: 'top'
+          });
+
+          extend(input.style, {
+            position: 'absolute',
+            top: 0,
+            right: 0,
+            fontFamily: 'Arial',
+            // 4 persons reported this, the max values that worked for them were 243, 236, 236, 118
+            fontSize: '118px',
+            margin: 0,
+            padding: 0,
+            opacity: 0,
+            filter: 'alpha(opacity=0)',
+            cursor: 'pointer'
+          });
+
+          domNode.appendChild(input);
+        }
+        // When new files are added, simply append them to the overall list
+        addEvent(input, 'change', this.inputChangeEvent);
+      }, this);
+    },
+    assignDrop: function () {
+      // not supported
+    },
+    unAssignDrop: function () {
+      // not supported
+    },
+    isUploading: function () {
+      var uploading = false;
+      each(this.files, function (file) {
+        if (file.isUploading()) {
+          uploading = true;
+          return false;
+        }
+      });
+      return uploading;
+    },
+    upload: function () {
+      // Kick off the queue
+      var files = 0;
+      each(this.files, function (file) {
+        if (file.progress() == 1 || file.isPaused()) {
+          return;
+        }
+        if (file.isUploading()) {
+          files++;
+          return;
+        }
+        if (files++ >= this.opts.simultaneousUploads) {
+          return false;
+        }
+        if (files == 1) {
+          this.fire('uploadStart');
+        }
+        file.send();
+      }, this);
+      if (!files) {
+        this.fire('complete');
+      }
+    },
+    pause: function () {
+      each(this.files, function (file) {
+        file.pause();
+      });
+    },
+    resume: function () {
+      each(this.files, function (file) {
+        file.resume();
+      });
+    },
+    progress: function () {
+      var totalDone = 0;
+      var totalFiles = 0;
+      each(this.files, function (file) {
+        totalDone += file.progress();
+        totalFiles++;
+      });
+      return totalFiles > 0 ? totalDone / totalFiles : 0;
+    },
+    addFiles: function (elementsList, event) {
+      var files = [];
+      each(elementsList, function (element) {
+        // is domElement ?
+        if (element.nodeType === 1 && element.value) {
+          var f = new FustyFlowFile(this, element);
+          if (this.fire('fileAdded', f, event)) {
+            files.push(f);
+          }
+        }
+      }, this);
+      if (this.fire('filesAdded', files, event)) {
+        each(files, function (file) {
+          if (this.opts.singleFile && this.files.length > 0) {
+            this.removeFile(this.files[0]);
+          }
+          this.files.push(file);
+        }, this);
+      }
+      this.fire('filesSubmitted', files, event);
+    },
+    addFile: function (file, event) {
+      this.addFiles([file], event);
+    },
+    generateUniqueIdentifier: function (element) {
+      var custom = this.opts.generateUniqueIdentifier;
+      if (typeof custom === 'function') {
+        return custom(element);
+      }
+      return 'xxxxxxxx-xxxx-yxxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
+        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
+        return v.toString(16);
+      });
+    },
+    getFromUniqueIdentifier: function (uniqueIdentifier) {
+      var ret = false;
+      each(this.files, function (f) {
+        if (f.uniqueIdentifier == uniqueIdentifier) ret = f;
+      });
+      return ret;
+    },
+    removeFile: function (file) {
+      for (var i = this.files.length - 1; i >= 0; i--) {
+        if (this.files[i] === file) {
+          this.files.splice(i, 1);
+        }
+      }
+    },
+    getSize: function () {
+      // undefined
+    },
+    timeRemaining: function () {
+      // undefined
+    },
+    sizeUploaded: function () {
+      // undefined
+    }
+  };
+
+  function FustyFlowFile(flowObj, element) {
+    this.flowObj = flowObj;
+    this.element = element;
+    this.name = element.value && element.value.replace(/.*(\/|\\)/, "");
+    this.relativePath = this.name;
+    this.uniqueIdentifier = flowObj.generateUniqueIdentifier(element);
+    this.iFrame = null;
+
+    this.finished = false;
+    this.error = false;
+    this.paused = false;
+
+    var $ = this;
+    this.iFrameLoaded = function (event) {
+      // when we remove iframe from dom
+      // the request stops, but in IE load
+      // event fires
+      if (!$.iFrame || !$.iFrame.parentNode) {
+        return;
+      }
+      $.finished = true;
+      try {
+        // fixing Opera 10.53
+        if ($.iFrame.contentDocument &&
+          $.iFrame.contentDocument.body &&
+          $.iFrame.contentDocument.body.innerHTML == "false") {
+          // In Opera event is fired second time
+          // when body.innerHTML changed from false
+          // to server response approx. after 1 sec
+          // when we upload file with iframe
+          return;
+        }
+      } catch (error) {
+        //IE may throw an "access is denied" error when attempting to access contentDocument
+        $.error = true;
+        $.abort();
+        $.flowObj.fire('fileError', $, error);
+        return;
+      }
+      // iframe.contentWindow.document - for IE<7
+      var doc = $.iFrame.contentDocument || $.iFrame.contentWindow.document;
+      var innerHtml = doc.body.innerHTML;
+      if ($.flowObj.opts.matchJSON) {
+        innerHtml = /(\{.*\})/.exec(innerHtml)[0];
+      }
+
+      $.abort();
+      $.flowObj.fire('fileSuccess', $, innerHtml);
+      $.flowObj.upload();
+    };
+    this.bootstrap();
+  }
+
+  FustyFlowFile.prototype = {
+    getExtension: Flow.FlowFile.prototype.getExtension,
+    getType: function () {
+      // undefined
+    },
+    send: function () {
+      if (this.finished) {
+        return;
+      }
+      var o = this.flowObj.opts;
+      var form = this.createForm();
+      var params = o.query;
+      if (isFunction(params)) {
+        params = params(this);
+      }
+      params[o.fileParameterName] = this.element;
+      params['flowFilename'] = this.name;
+      params['flowRelativePath'] = this.relativePath;
+      params['flowIdentifier'] = this.uniqueIdentifier;
+
+      this.addFormParams(form, params);
+      addEvent(this.iFrame, 'load', this.iFrameLoaded);
+      form.submit();
+      removeElement(form);
+    },
+    abort: function (noupload) {
+      if (this.iFrame) {
+        this.iFrame.setAttribute('src', 'java' + String.fromCharCode(115) + 'cript:false;');
+        removeElement(this.iFrame);
+        this.iFrame = null;
+        !noupload && this.flowObj.upload();
+      }
+    },
+    cancel: function () {
+      this.flowObj.removeFile(this);
+      this.abort();
+    },
+    retry: function () {
+      this.bootstrap();
+      this.flowObj.upload();
+    },
+    bootstrap: function () {
+      this.abort(true);
+      this.finished = false;
+      this.error = false;
+    },
+    timeRemaining: function () {
+      // undefined
+    },
+    sizeUploaded: function () {
+      // undefined
+    },
+    resume: function () {
+      this.paused = false;
+      this.flowObj.upload();
+    },
+    pause: function () {
+      this.paused = true;
+      this.abort();
+    },
+    isUploading: function () {
+      return this.iFrame !== null;
+    },
+    isPaused: function () {
+      return this.paused;
+    },
+    isComplete: function () {
+      return this.progress() === 1;
+    },
+    progress: function () {
+      if (this.error) {
+        return 1;
+      }
+      return this.finished ? 1 : 0;
+    },
+
+    createIframe: function () {
+      var iFrame = (/MSIE (6|7|8)/).test(navigator.userAgent) ?
+        document.createElement('<iframe name="' + this.uniqueIdentifier + '_iframe' + '">') :
+        document.createElement('iframe');
+
+      iFrame.setAttribute('id', this.uniqueIdentifier + '_iframe_id');
+      iFrame.setAttribute('name', this.uniqueIdentifier + '_iframe');
+      iFrame.style.display = 'none';
+      document.body.appendChild(iFrame);
+      return iFrame;
+    },
+    createForm: function() {
+      var target = this.flowObj.opts.target;
+      if (typeof target === "function") {
+        target = target.apply(null);
+      }
+
+      var form = document.createElement('form');
+      form.encoding = "multipart/form-data";
+      form.method = "POST";
+      form.setAttribute('action', target);
+      if (!this.iFrame) {
+        this.iFrame = this.createIframe();
+      }
+      form.setAttribute('target', this.iFrame.name);
+      form.style.display = 'none';
+      document.body.appendChild(form);
+      return form;
+    },
+    addFormParams: function(form, params) {
+      var input;
+      each(params, function (value, key) {
+        if (value && value.nodeType === 1) {
+          input = value;
+        } else {
+          input = document.createElement('input');
+          input.setAttribute('value', value);
+        }
+        input.setAttribute('name', key);
+        form.appendChild(input);
+      });
+    }
+  };
+
+  FustyFlow.FustyFlowFile = FustyFlowFile;
+
+  if (typeof module !== 'undefined') {
+    module.exports = FustyFlow;
+  } else if (typeof define === "function" && define.amd) {
+    // AMD/requirejs: Define the module
+    define(function(){
+      return FustyFlow;
+    });
+  } else {
+    window.FustyFlow = FustyFlow;
+  }
+})(window.Flow, window, document);
diff --git js/mage/adminhtml/product.js js/mage/adminhtml/product.js
index 3bbc741..9be1ef1 100644
--- js/mage/adminhtml/product.js
+++ js/mage/adminhtml/product.js
@@ -34,18 +34,18 @@ Product.Gallery.prototype = {
     idIncrement :1,
     containerId :'',
     container :null,
-    uploader :null,
     imageTypes : {},
-    initialize : function(containerId, uploader, imageTypes) {
+    initialize : function(containerId, imageTypes) {
         this.containerId = containerId, this.container = $(this.containerId);
-        this.uploader = uploader;
         this.imageTypes = imageTypes;
-        if (this.uploader) {
-            this.uploader.onFilesComplete = this.handleUploadComplete
-                    .bind(this);
-        }
-        // this.uploader.onFileProgress = this.handleUploadProgress.bind(this);
-        // this.uploader.onFileError = this.handleUploadError.bind(this);
+
+        document.on('uploader:fileSuccess', function(event) {
+            var memo = event.memo;
+            if(memo && this._checkCurrentContainer(memo.containerId)) {
+                this.handleUploadComplete([{response: memo.response}]);
+            }
+        }.bind(this));
+
         this.images = this.getElement('save').value.evalJSON();
         this.imagesValues = this.getElement('save_image').value.evalJSON();
         this.template = new Template('<tr id="__id__" class="preview">' + this
@@ -56,6 +56,9 @@ Product.Gallery.prototype = {
         varienGlobalEvents.attachEventHandler('moveTab', this.onImageTabMove
                 .bind(this));
     },
+    _checkCurrentContainer: function(child) {
+        return $(this.containerId).down('#' + child);
+    },
     onImageTabMove : function(event) {
         var imagesTab = false;
         this.container.ancestors().each( function(parentItem) {
@@ -113,7 +116,6 @@ Product.Gallery.prototype = {
             newImage.disabled = 0;
             newImage.removed = 0;
             this.images.push(newImage);
-            this.uploader.removeFile(item.id);
         }.bind(this));
         this.container.setHasChanges();
         this.updateImages();
diff --git js/mage/adminhtml/uploader/instance.js js/mage/adminhtml/uploader/instance.js
new file mode 100644
index 0000000..483b2af
--- /dev/null
+++ js/mage/adminhtml/uploader/instance.js
@@ -0,0 +1,508 @@
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    design
+ * @package     default_default
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+(function(flowFactory, window, document) {
+'use strict';
+    window.Uploader = Class.create({
+
+        /**
+         * @type {Boolean} Are we in debug mode?
+         */
+        debug: false,
+
+        /**
+         * @constant
+         * @type {String} templatePattern
+         */
+        templatePattern: /(^|.|\r|\n)({{(\w+)}})/,
+
+        /**
+         * @type {JSON} Array of elements ids to instantiate DOM collection
+         */
+        elementsIds: [],
+
+        /**
+         * @type {Array.<HTMLElement>} List of elements ids across all uploader functionality
+         */
+        elements: [],
+
+        /**
+         * @type {(FustyFlow|Flow)} Uploader object instance
+         */
+        uploader: {},
+
+        /**
+         * @type {JSON} General Uploader config
+         */
+        uploaderConfig: {},
+
+        /**
+         * @type {JSON} browseConfig General Uploader config
+         */
+        browseConfig: {},
+
+        /**
+         * @type {JSON} Misc settings to manipulate Uploader
+         */
+        miscConfig: {},
+
+        /**
+         * @type {Array.<String>} Sizes in plural
+         */
+        sizesPlural: ['bytes', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
+
+        /**
+         * @type {Number} Precision of calculation during convetion to human readable size format
+         */
+        sizePrecisionDefault: 3,
+
+        /**
+         * @type {Number} Unit type conversion kib or kb, etc
+         */
+        sizeUnitType: 1024,
+
+        /**
+         * @type {String} Default delete button selector
+         */
+        deleteButtonSelector: '.delete',
+
+        /**
+         * @type {Number} Timeout of completion handler
+         */
+        onCompleteTimeout: 1000,
+
+        /**
+         * @type {(null|Array.<FlowFile>)} Files array stored for success event
+         */
+        files: null,
+
+
+        /**
+         * @name Uploader
+         *
+         * @param {JSON} config
+         *
+         * @constructor
+         */
+        initialize: function(config) {
+            this.elementsIds = config.elementIds;
+            this.elements = this.getElements(this.elementsIds);
+
+            this.uploaderConfig = config.uploaderConfig;
+            this.browseConfig = config.browseConfig;
+            this.miscConfig =  config.miscConfig;
+
+            this.uploader = flowFactory(this.uploaderConfig);
+
+            this.attachEvents();
+
+            /**
+             * Bridging functions to retain functionality of existing modules
+             */
+            this.formatSize = this._getPluralSize.bind(this);
+            this.upload = this.onUploadClick.bind(this);
+            this.onContainerHideBefore = this.onTabChange.bind(this);
+        },
+
+        /**
+         * Array of strings containing elements ids
+         *
+         * @param {JSON.<string, Array.<string>>} ids as JSON map,
+         *      {<type> => ['id1', 'id2'...], <type2>...}
+         * @returns {Array.<HTMLElement>} An array of DOM elements
+         */
+        getElements: function (ids) {
+            /** @type {Hash} idsHash */
+            var idsHash = $H(ids);
+
+            idsHash.each(function (id) {
+                var result = this.getElementsByIds(id.value);
+
+                idsHash.set(id.key, result);
+            }.bind(this));
+
+            return idsHash.toObject();
+        },
+
+        /**
+         * Get HTMLElement from hash values
+         *
+         * @param {(Array|String)}ids
+         * @returns {(Array.<HTMLElement>|HTMLElement)}
+         */
+        getElementsByIds: function (ids) {
+            var result = [];
+            if(ids && Object.isArray(ids)) {
+                ids.each(function(fromId) {
+                    var DOMElement = $(fromId);
+
+                    if (DOMElement) {
+                        // Add it only if it's valid HTMLElement, otherwise skip.
+                        result.push(DOMElement);
+                    }
+                });
+            } else {
+                result = $(ids)
+            }
+
+            return result;
+        },
+
+        /**
+         * Attach all types of events
+         */
+        attachEvents: function() {
+            this.assignBrowse();
+
+            this.uploader.on('filesSubmitted', this.onFilesSubmitted.bind(this));
+
+            this.uploader.on('uploadStart', this.onUploadStart.bind(this));
+
+            this.uploader.on('fileSuccess', this.onFileSuccess.bind(this));
+            this.uploader.on('complete', this.onSuccess.bind(this));
+
+            if(this.elements.container && !this.elements.delete) {
+                this.elements.container.on('click', this.deleteButtonSelector, this.onDeleteClick.bind(this));
+            } else {
+                if(this.elements.delete) {
+                    this.elements.delete.on('click', Event.fire.bind(this, document, 'upload:simulateDelete', {
+                        containerId: this.elementsIds.container
+                    }));
+                }
+            }
+            if(this.elements.upload) {
+                this.elements.upload.invoke('on', 'click', this.onUploadClick.bind(this));
+            }
+            if(this.debug) {
+                this.uploader.on('catchAll', this.onCatchAll.bind(this));
+            }
+        },
+
+        onTabChange: function (successFunc) {
+            if(this.uploader.files.length && !Object.isArray(this.files)) {
+                if(confirm(
+                        this._translate('There are files that were selected but not uploaded yet. After switching to another tab your selections will be lost. Do you wish to continue ?')
+                   )
+                ) {
+                    if(Object.isFunction(successFunc)) {
+                        successFunc();
+                    } else {
+                        this._handleDelete(this.uploader.files);
+                        document.fire('uploader:fileError', {
+                            containerId: this.elementsIds.container
+                        });
+                    }
+                } else {
+                    return 'cannotchange';
+                }
+            }
+        },
+
+        /**
+         * Assign browse buttons to appropriate targets
+         */
+        assignBrowse: function() {
+            if (this.elements.browse && this.elements.browse.length) {
+                this.uploader.assignBrowse(
+                    this.elements.browse,
+                    this.browseConfig.isDirectory || false,
+                    this.browseConfig.singleFile || false,
+                    this.browseConfig.attributes || {}
+                );
+            }
+        },
+
+        /**
+         * @event
+         * @param {Array.<FlowFile>} files
+         */
+        onFilesSubmitted: function (files) {
+            files.filter(function (file) {
+                if(this._checkFileSize(file)) {
+                    alert(
+                        this._translate('Maximum allowed file size for upload is') +
+                        " " + this.miscConfig.maxSizePlural + "\n" +
+                        this._translate('Please check your server PHP settings.')
+                    );
+                    file.cancel();
+                    return false;
+                }
+                return true;
+            }.bind(this)).each(function (file) {
+                this._handleUpdateFile(file);
+            }.bind(this));
+        },
+
+        _handleUpdateFile: function (file) {
+            var replaceBrowseWithRemove = this.miscConfig.replaceBrowseWithRemove;
+            if(replaceBrowseWithRemove) {
+                document.fire('uploader:simulateNewUpload', { containerId: this.elementsIds.container });
+            }
+            this.elements.container
+                [replaceBrowseWithRemove ? 'update':'insert'](this._renderFromTemplate(
+                    this.elements.templateFile,
+                    {
+                        name: file.name,
+                        size: file.size ? '(' + this._getPluralSize(file.size) + ')' : '',
+                        id: file.uniqueIdentifier
+                    }
+                )
+            );
+        },
+
+        /**
+         * Upload button is being pressed
+         *
+         * @event
+         */
+        onUploadStart: function () {
+            var files = this.uploader.files;
+
+            files.each(function (file) {
+                var id = file.uniqueIdentifier;
+
+                this._getFileContainerById(id)
+                    .removeClassName('new')
+                    .removeClassName('error')
+                    .addClassName('progress');
+                this._getProgressTextById(id).update(this._translate('Uploading...'));
+
+                var deleteButton = this._getDeleteButtonById(id);
+                if(deleteButton) {
+                    this._getDeleteButtonById(id).hide();
+                }
+            }.bind(this));
+
+            this.files = this.uploader.files;
+        },
+
+        /**
+         * Get file-line container by id
+         *
+         * @param {String} id
+         * @returns {HTMLElement}
+         * @private
+         */
+        _getFileContainerById: function (id) {
+            return $(id + '-container');
+        },
+
+        /**
+         * Get text update container
+         *
+         * @param id
+         * @returns {*}
+         * @private
+         */
+        _getProgressTextById: function (id) {
+            return this._getFileContainerById(id).down('.progress-text');
+        },
+
+        _getDeleteButtonById: function(id) {
+            return this._getFileContainerById(id).down('.delete');
+        },
+
+        /**
+         * Handle delete button click
+         *
+         * @event
+         * @param {Event} e
+         */
+        onDeleteClick: function (e) {
+            var element = Event.findElement(e);
+            var id = element.id;
+            if(!id) {
+                id = element.up(this.deleteButtonSelector).id;
+            }
+            this._handleDelete([this.uploader.getFromUniqueIdentifier(id)]);
+        },
+
+        /**
+         * Complete handler of uploading process
+         *
+         * @event
+         */
+        onSuccess: function () {
+            document.fire('uploader:success', { files: this.files });
+            this.files = null;
+        },
+
+        /**
+         * Successfully uploaded file, notify about that other components, handle deletion from queue
+         *
+         * @param {FlowFile} file
+         * @param {JSON} response
+         */
+        onFileSuccess: function (file, response) {
+            response = response.evalJSON();
+            var id = file.uniqueIdentifier;
+            var error = response.error;
+            this._getFileContainerById(id)
+                .removeClassName('progress')
+                .addClassName(error ? 'error': 'complete')
+            ;
+            this._getProgressTextById(id).update(this._translate(
+                error ? this._XSSFilter(error) :'Complete'
+            ));
+
+            setTimeout(function() {
+                if(!error) {
+                    document.fire('uploader:fileSuccess', {
+                        response: Object.toJSON(response),
+                        containerId: this.elementsIds.container
+                    });
+                } else {
+                    document.fire('uploader:fileError', {
+                        containerId: this.elementsIds.container
+                    });
+                }
+                this._handleDelete([file]);
+            }.bind(this) , !error ? this.onCompleteTimeout: this.onCompleteTimeout * 3);
+        },
+
+        /**
+         * Upload button click event
+         *
+         * @event
+         */
+        onUploadClick: function () {
+            try {
+                this.uploader.upload();
+            } catch(e) {
+                if(console) {
+                    console.error(e);
+                }
+            }
+        },
+
+        /**
+         * Event for debugging purposes
+         *
+         * @event
+         */
+        onCatchAll: function () {
+            if(console.group && console.groupEnd && console.trace) {
+                var args = [].splice.call(arguments, 1);
+                console.group();
+                    console.info(arguments[0]);
+                    console.log("Uploader Instance:", this);
+                    console.log("Event Arguments:", args);
+                    console.trace();
+                console.groupEnd();
+            } else {
+                console.log(this, arguments);
+            }
+        },
+
+        /**
+         * Handle deletition of files
+         * @param {Array.<FlowFile>} files
+         * @private
+         */
+        _handleDelete: function (files) {
+            files.each(function (file) {
+                file.cancel();
+                var container = $(file.uniqueIdentifier + '-container');
+                if(container) {
+                    container.remove();
+                }
+            }.bind(this));
+        },
+
+        /**
+         * Check whenever file size exceeded permitted amount
+         *
+         * @param {FlowFile} file
+         * @returns {boolean}
+         * @private
+         */
+        _checkFileSize: function (file) {
+            return file.size > this.miscConfig.maxSizeInBytes;
+        },
+
+        /**
+         * Make a translation of string
+         *
+         * @param {String} text
+         * @returns {String}
+         * @private
+         */
+        _translate: function (text) {
+            try {
+                return Translator.translate(text);
+            }
+            catch(e){
+                return text;
+            }
+        },
+
+        /**
+         * Render from given template and given variables to assign
+         *
+         * @param {HTMLElement} template
+         * @param {JSON} vars
+         * @returns {String}
+         * @private
+         */
+        _renderFromTemplate: function (template, vars) {
+            var t = new Template(this._XSSFilter(template.innerHTML), this.templatePattern);
+            return t.evaluate(vars);
+        },
+
+        /**
+         * Format size with precision
+         *
+         * @param {Number} sizeInBytes
+         * @param {Number} [precision]
+         * @returns {String}
+         * @private
+         */
+        _getPluralSize: function (sizeInBytes, precision) {
+                if(sizeInBytes == 0) {
+                    return 0 + this.sizesPlural[0];
+                }
+                var dm = (precision || this.sizePrecisionDefault) + 1;
+                var i = Math.floor(Math.log(sizeInBytes) / Math.log(this.sizeUnitType));
+
+                return (sizeInBytes / Math.pow(this.sizeUnitType, i)).toPrecision(dm) + ' ' + this.sizesPlural[i];
+        },
+
+        /**
+         * Purify template string to prevent XSS attacks
+         *
+         * @param {String} str
+         * @returns {String}
+         * @private
+         */
+        _XSSFilter: function (str) {
+            return str
+                .stripScripts()
+                // Remove inline event handlers like onclick, onload, etc
+                .replace(/(on[a-z]+=["][^"]+["])(?=[^>]*>)/img, '')
+                .replace(/(on[a-z]+=['][^']+['])(?=[^>]*>)/img, '')
+            ;
+        }
+    });
+})(fustyFlowFactory, window, document);
diff --git lib/Unserialize/Parser.php lib/Unserialize/Parser.php
index 423902a..2c01684 100644
--- lib/Unserialize/Parser.php
+++ lib/Unserialize/Parser.php
@@ -34,6 +34,7 @@ class Unserialize_Parser
     const TYPE_DOUBLE = 'd';
     const TYPE_ARRAY = 'a';
     const TYPE_BOOL = 'b';
+    const TYPE_NULL = 'N';
 
     const SYMBOL_QUOTE = '"';
     const SYMBOL_SEMICOLON = ';';
diff --git lib/Unserialize/Reader/Arr.php lib/Unserialize/Reader/Arr.php
index caa979e..cd37804 100644
--- lib/Unserialize/Reader/Arr.php
+++ lib/Unserialize/Reader/Arr.php
@@ -101,7 +101,10 @@ class Unserialize_Reader_Arr
         if ($this->_status == self::READING_VALUE) {
             $value = $this->_reader->read($char, $prevChar);
             if (!is_null($value)) {
-                $this->_result[$this->_reader->key] = $value;
+                $this->_result[$this->_reader->key] =
+                    ($value == Unserialize_Reader_Null::NULL_VALUE && $prevChar == Unserialize_Parser::TYPE_NULL)
+                        ? null
+                        : $value;
                 if (count($this->_result) < $this->_length) {
                     $this->_reader = new Unserialize_Reader_ArrKey();
                     $this->_status = self::READING_KEY;
diff --git lib/Unserialize/Reader/ArrValue.php lib/Unserialize/Reader/ArrValue.php
index d2a4937..c6c0221 100644
--- lib/Unserialize/Reader/ArrValue.php
+++ lib/Unserialize/Reader/ArrValue.php
@@ -84,6 +84,10 @@ class Unserialize_Reader_ArrValue
                     $this->_reader = new Unserialize_Reader_Dbl();
                     $this->_status = self::READING_VALUE;
                     break;
+                case Unserialize_Parser::TYPE_NULL:
+                    $this->_reader = new Unserialize_Reader_Null();
+                    $this->_status = self::READING_VALUE;
+                    break;
                 default:
                     throw new Exception('Unsupported data type ' . $char);
             }
diff --git lib/Unserialize/Reader/Null.php lib/Unserialize/Reader/Null.php
new file mode 100644
index 0000000..f382b65
--- /dev/null
+++ lib/Unserialize/Reader/Null.php
@@ -0,0 +1,64 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Unserialize
+ * @package     Unserialize_Reader_Null
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/**
+ * Class Unserialize_Reader_Null
+ */
+class Unserialize_Reader_Null
+{
+    /**
+     * @var int
+     */
+    protected $_status;
+
+    /**
+     * @var string
+     */
+    protected $_value;
+
+    const NULL_VALUE = 'null';
+
+    const READING_VALUE = 1;
+
+    /**
+     * @param string $char
+     * @param string $prevChar
+     * @return string|null
+     */
+    public function read($char, $prevChar)
+    {
+        if ($prevChar == Unserialize_Parser::SYMBOL_SEMICOLON) {
+            $this->_value = self::NULL_VALUE;
+            $this->_status = self::READING_VALUE;
+            return null;
+        }
+
+        if ($this->_status == self::READING_VALUE && $char == Unserialize_Parser::SYMBOL_SEMICOLON) {
+            return $this->_value;
+        }
+        return null;
+    }
+}
diff --git skin/adminhtml/default/default/boxes.css skin/adminhtml/default/default/boxes.css
index a86c023..c93537e 100644
--- skin/adminhtml/default/default/boxes.css
+++ skin/adminhtml/default/default/boxes.css
@@ -78,7 +78,7 @@
     z-index:501;
     }
 #loading-mask {
-    background:background:url(../images/blank.gif) repeat;
+    background:url(images/blank.gif) repeat;
     position:absolute;
     color:#d85909;
     font-size:1.1em;
@@ -1395,8 +1395,6 @@ ul.super-product-attributes { padding-left:15px; }
 .uploader .file-row-info .file-info-name  { font-weight:bold; }
 .uploader .file-row .progress-text { float:right; font-weight:bold; }
 .uploader .file-row .delete-button { float:right; }
-.uploader .buttons { float:left; }
-.uploader .flex { float:right; }
 .uploader .progress { border:1px solid #f0e6b7; background-color:#feffcc; }
 .uploader .error { border:1px solid #aa1717; background-color:#ffe6de; }
 .uploader .error .progress-text { padding-right:10px; }
diff --git skin/adminhtml/default/default/media/flex.swf skin/adminhtml/default/default/media/flex.swf
deleted file mode 100644
index a8ecaa0..0000000
--- skin/adminhtml/default/default/media/flex.swf
+++ /dev/null
@@ -1,70 +0,0 @@
-CWS	-~  x�̽XK�8���i�޻��E��.X@PH	AB�Ih"`î�{��X����E,�b��������~���{�6;sΜ3sʜ�M��\��A�� �.	R�C�H�@���wTP�in�P$��5k�L���䔓����(��:�xyy99�:��:��<���� �ZX���xR�$-S�&�buN�8K�cm�����d��%�,S�N<!/�'�I�\] ��7_,���|9���4.c�� ���9�l�_ȑ
-8u5�hdi2!��?E��3
-�2�:��P�H���L!O���y*t�('%�!sR�%K8�<�.X"K��E�\Y�\.���,Y�PJ�!TH�s�H�ɂx�4Qf��������!s��"��e�Z
-�ϓHx)C;�3q��O�B.|*)b.�D�D9YP�,��N����	'�,�Am�D2�
-�+E����j(�t稕�+�7�P�21O�e�妉��0�f�Q�da�^�RW}D�`&��T
-]��?8-:�K,R�0X'���4��?�2�s��
-���àB7���a"h�G�b�!�L%	/�'�7����)����ޝ~���)I��,{��w�d
-�z��K����������#���g��4Y'3H���$yF=H�~���N%%Ie�L��ap�S#�D��II�I0��A)2��#ĝV��x)����aC��0��Ȕ2�̸f��'��8�)��eh�h7����҄�4��;��hҬd)�!N�G���m�	c�)q�S@Qp�]1@�GD������
-�d|�i@d �XG'�D��'�Nc9���*�
-������
-�aL7F�6J	'���IdOF��ps���C����TX�8sD�e������x0�Ȣ��i�
-��z��`x6U5�s҄�S��C9���z �^�J��EɸE��0�,��6E�Nej�ꪓm]]]7�;�?ѡ��������O�����N��% 6�.�ndD(STT��54��I:�=�z�DUc`B3�ր���f�4�͜�7�$�Q��(��DJRBI�(사Fc �@QM(���j��J�CQ}��!J6BQc5AQS5CQsX��%
-�P�
-�Q�EmQ�E�Q���(ꈢN(������~(ꁢ�(ꅢ�(s ����
-�B�?���@�d ���HCA
-�Q0#P��XT/�K@��P�AA2j���E� 
-D���(�	
-�(���Y�r6���*��|L(���P�9�P�y ՟a JX��}1�/�K�m���
-Ĭ(y5���k-�����i��+���� !!;��/ lM��i�	��&�2�;=�(������E P�@	�uoN��wj7���"� ���FJe��� �NW�Uu��k �&�	��$C 4��d��P}�( D� L#�(�a� ������� ZV Q��5@4l B����F�==����4P�%��!z}�}G@�C^Np�}�D�ҙ�X��.��J!��n�9�ؗB2'�)���QPs
-уB6G�:��S�d�F6���A���-
-	P�9��� 8� ���fŔ#	!Z' �c�#�P(*�^휠d��B&��9T;'��|�.���%��\�Z}=,��D7K��-��%Y�Q�D:��v�DnY"u�fl�Y���@'��T`�hg�.�K��#�JT��$ZX,�Lz���D���U�$�$�	郰��>�D[ye(��&�F�"l?6���:���P,KD��%��J�aEj,�:i�*Ah	�7�Vt�p�����=Q/A�2%\��zl
-?�m��ҋFl"l(JD�a��iq���޴�K��m��`F�}��n�j�����qI���P��%'�X��%��L��H&�$�%�	�7B�A
- �Zu�� �*�%��@�� ��j���$:�0!� ���e�}�a� �FMH8P�^� ��B:��P�K�viw˙L�3 X"��!�v�AV]
-�OԲh%�u@"Ԁj	��B&A?B#�yTE}5ԧm��:>"[lD��Sq��"�D�`e�����P,&��dW�J��ܨ��T��*�T;�8�B����3�����{L)B�"h�B�0c�	�:]"s�H$aX��NÀj
-pPawP� ��&��fM��,N�,��vU�T���� &Y�yp��D(�+-�S6G	�Ʉ�dD� z�FG��`k���Ă��R�js 6�갩6`Ή�/�M5ؼ�Oؙ��#�		Я�L�����}��}1��F���b�-��Y�!y-��D���ܸ^��Ğ� �tq�(b
-�L&! hI"��a$I�"	F���D��ut�u�[�/Px,����ǰ�;*�|!^I�ׄ�䐐��@.��0>ܓ�un�F�	P#j�W(A���{�?�!�.+���m������	�ݪ�����Am�G`�A��a�Q���N���%a������	��H-�G�.�j)L�i�̆�XSm��Ѭ��Ʋ�3[�̖:�e��,gv�3�	�b���%`��:� V;â. &���U��G$3�3@�b1pI5x8�S�.e[c��s؄��`�/��Q�0ıփ:l�&�!�k�0�0U�p�a;��<(�)���9�ɤ���6�
-��&�Vׄ���'��V;�ؘ�X#aG#0���n_��C�^b��%uH� �3pc �ڈ �$�����
-��p#��qتg �ܩXs8\�
-4P>6\K48B�EǦ�Z�i�!��$��Xb�"��3ܿ�s��y�v�Z|�9�CR�P��}�*�s��у�7U�Ў�*٩�2�!�/�_��i�"قPꮰ�^�E��T7�X�m��+�����M��02�+& 	�&ې/O��F���'lH9��	n���	��cx'�����6�����^�/
-0K?*����)��8	26�����%<N8;�@m�m�\޴ە����4
-�K����ߨ��RV�)���UΤ�'��ΛVft
-A�Ağ/�B<�v��(��ի�7����O����{������%$�w�`��F�q����v߄�u�S��w?�|���d�@{Sr����M[�l�%�����"�������2��"�,�ݼR��$�|��!�vާ-�	������z����z=��y���R�s&C����'��l��S������O˼%�����Q;G���@��!dUDɽ[��}Шa��~M�\$<{�����<�aQfw��G��'�ߺ��j�b����W^�ܣ�?c�������'��಑��W��N��~ɻ�_��j鮐{+\��~�=w����!?	�J���y7���7��7b�M6�U��e�����&�{?���V�8�X�����.�_�~x{�)m����ϛ�O�f�|�7:Rw�FM�{��cו{#-�v����b����s���
-^������]����������k����e�֏��m_X����mи�qhX�3c3�{�o��P{�}ֶ/-޽&�u7�8�5vJɫKo��;�ap���zJ���CZ�;�i#�ͯ�3��=�0㵒yi�Z�9�_|�s9����
-VM�9g۰���*K7���$ٿ�{ak�i�W�'ْ}n.c�����HU}2�Q�f�c�N�Ů	k��>\�{��֤_J�U7�h�0�0�)b
-��U��2bJ%{]��qs�VP�̼�Ǐ����o-���s�KW\h;�r/�_e��"��miSS�}CQ񗤦v""�Z�֩яɘ����N�n9R�|�Ƈ~�Nl�N��d��RljGo$���mC��ku-=���aB��LҏqQ?=fü��'u�&,,(6�_���0�?.�������x!}��8�[;q���+Gd�>h�ii��N�}��Rg���U�s.�Y��]��Ф�6UǱO���<�酉���_%?/�X�o7��;f~Y��H��C�Z:�M�,v�O��X�����k�̀���������ï�ÎH�/
-Ύ\�x����%��K/�.^p���S�$݄��{���8�-�p���f���S��d^֮z��(}<��ڵn��$�N��/G�~�)�����.��f��Ieo֣ʖk7M}���s�ۣ��^��=G����9R�_;���譞�l�?�;lX���WgU����ҋ.m+�8��"�[x���OE�+����{�3)cI�4}�|��OK�W}�'����F��G��ؘ��N$����V���N��<�e�h�K���f��_W���Ν��>�##;��´�L�_���l������b������d"yuG�^�>��ƆS$}��sϥ�>����Μ��+��rV/�c����o%V=3k�4��㳍�g�N��f��*��V��Y�����#�V~�w�7O�O�ڷg���	G���Ⱥ �<����C�.li�>!?�ؘ��o�6�;yD�[�>������F]��A:�dY��V�շ@[�}>�N���9�:�J�Lu��`$��*_��{鱖�o>K,x�,޴kX/�z>�Akc�y#Ú�S���s���O��e`?w�|E�ńFQ]è��wߗD�X���`U�ɯ���o��^8W I9��fc�y�z�"�_v.z������/1��4{���_~�zr<�3)�Ǭ���о�k-��E�o��n8.>l[V" �Y�~0��E��#�����ͷX�p�N�>��������=��s�5i�IQ����'�^]<r����!�C��m�����W�/o-,��U?6ha|�%���&�w+6���%ڸ��;��C����l?��V������-{�X��\}߶}���:�B�б�W�P��c����E����S�4	&�W}��;�;�rc��#��I�h��#o�@I�̢�����K���ǻ�����4_�OCg���������6�S�f��o���>�fE�������[�GmO7k��q{��˓�FO#J|�V��t���}Xf=�?��k��M���?y��m�Ӯ;��\�R��:账�̧��s��_.ptr���r��'��4�K.L̘�m���sV~�F��@�X������'b]tT��g鮭F�f��9=]���4hh�:��k�*E��B�Vi�{PP�p�ɷ��|�}9��2�Úx���{˪�3�������J�~�5��:���u�/3�\��8`��[�*�GK��}��TY��O>\�Rj�5�/��c+�>��4���2�B�r����s��ƜW���|���W�~Vٚ8e�����M�k�{\�������5!�A�������̥MO�ԍ�ʝ3�+��Mۏ��ML6�Eo���}�꧟�3����������f��ؒ�e2y{�4��n̂���3�s�o�+B�6x����"��g�&
-�9�����+�������k2E�Ϗi����_�k��O�2��i�F���;0vu���c��}>N�y����E�.pA����><g��<��{}S�������o�#ƣ�QC�l�<v�ˤ6��c�������x��׫�%�:w�q�_WF�.�඲r`���/o�i�|��iɗ'�A-Y'�)��xIs���e.q��=2~\>XqOM�{W�d3+����{F4I��!u�.ߞ���pԴs����8;���j�w����������+��Wlv��U�����%_�*n��vQ�]RQ��m�_7:-˗������ש{e<}�mfӏ��/"N~ٲwt��mF���s�׭����Z�?n� ]�m���[5coa������Q����Hnt/��^��1��Hʅ<^�[��߃ל���y���6G�;Hf1uL��_�氇d��(�5�3�H�uLF
-8��8��o����ߟ�'ڑ��as�S�qyiVn���
-V�៣�^�6K���8��������;$��&�ُ�N���+���y#3w���~��{t�X�Wc/��PKU��sy��j�i��A�����T�tt~��%u��K�>@�:�&rU����,���m����r�c� Q�ح+E:�u�'�s��w���|t�Q�d��0_&lWӚ_<@wo����)~��^O}�;�0���K�O���Gl�L��/��8�3���}�=�زŸ$g����鿨��	�ͤ3Τ2��GFDX�������Ny_�$QQ�(��x�k��Wh��늧�<n\*�zm�m����z��i3#~Ա~͙������9w��Ϙ_[�
-��6����J�}M��M[�b�Dz��y\X��/~�ߔ�3�%n�k�����޳(�O�/9ݲ΃s|��y�Y'^^�_t����l��,Q\#mُ)y1E��$q���z-���^'k����_,I�|�i��}$I7_�;���̈�7������:_��Z���y��[Ѻ��ڗ��.;[��F��s��%���^��f��r4�-��(����|���+$�g<�]�vU��ᏩWm�������}��y�KSx�kS�9d��˵��/�:5�ۀm�W��?O����H2���~N�ۆj� ���:��k�ߝ}X4wBz�RƜC�o��ս>���R�� e�kK�O��*�jH�%.�IZ�<����i%�T��}Ez���G��]Qe��n�廡���pl٥^�~<�{mōk��>�g�����z7�����m�G��t���ݥI3��V�h�F��ꡝ{��/��1���ν�Ts퐸����_��H1��ۿ=ٿ�� *��^};v܀Ц�'g��K%�9�9��?Zʯ:�D�kޯʓ�����Lnx��X5���G��+l����,ԫ4��v�þ�I�YT0qoB��j��C��g��ܟq��V��Pm���0~w'��XP�=�QgБ���<m���}ض���r���ʳ}rtޜ�8�+@�~�\hqE�;zp�c�5�c��]��z~.�5�,�Ϳ���^��s�	���^qk�������嗕/W��ڛ��_e���93"N�^{$-���4�O�䟛�j՘�~�=���=�s�^8|V9g�����I~Dr1i������g��=���X9���*�JݵN���
-Z
-�����0���ɱ;^Äz���m�5��$#��"7���m���%����V]}8rf���i���\>�q�uA΢��;������T�Kɜ�y�;�rYb�C	Y����#�e�1�CW�Z�#�zчx��ր��A����5��1콋���g|mn�2ܒK��0���0�8O?��j���X�c��e�#F�XC�zZ�P����3��ܞ�
-֚����iA�j
-�R^R�8G�=��l����2M�KA��!�2�*��~�N���'NՐ+��S�6�F��o&��mooG7��J.����r}-:k�.���GH_�67_^B~�t���HYwr�q�_������7f>�;l\�:��?h�z◯�+�i�K?��-j���[�Z?��%�>�<�3�Ȍo���W��&��Ƈ~��?�=�鮟�?�*���7P��;��r��h_�b9��P������C@z����u���,	�'U�R���s��S���Z�ݡY�<��Hh�3�t��<��C�N��<h�qFW%,������
-Ӱü�a%��ͤt���p���~?���E��EB�<.�T��Q�]����)Y"���b�+�Bq2GH���p�C8�:r0N��
-9\R9<z�$-�'e�%HC��<����U��S��@;�)/*â��j��xC��a'��������@�b1
-+c@�}��"'eJę<�,
-f��}�y��uܫeP���p�&Ix�b	T_,I��B�')z$�|Rj?��ӥ��{?7OW����ț��ϳ��{_Ͼ�,zQũb�W/7g//O��yY�I.n^n}=]]=�P��Ix��#`Y����b+�u"; :�'�{�4���0QJ���4i�������I-��]3����R��&
-���Qo��Z+�F��q&G(��c�4�������CL���0��Y������)r��1-�R�����0
-V$0��C�#,ׂVJ��;\�T�+F���f�k���,�ct3�F`t��˗
-�L���,l�
-�2��-��ך��ް�|؝��%�O������h���ިcadc��#�d*	Ē�q�A]�f�(weN@�Lm�r�d�?�,K��4��_�)�HUpub+��N�Cn#�%��,��Mq")]&�V�ˌH�8N)상�@N�7adrRR����29\��Q���-�{ldt�f�T�řd.�J7R�J�/��J8)X̒��o�
-Q�Z�����*]4x[u��đO8�h���H���z�(�\,�E���R�sгT��SSᶫC��]/E�R����f�9�{���1��\MX��nH����L�l��ܳ�������'�~
-�O)��ʦ�'_�Ktc9Tl�x�6�c��4MԋC&�~�@��G�s�Rl��,26li/���4�#����0��0\�e/1�W:����J��w.��6�w)p$�`O��#xڜ�2�I�x����R�2�ry�h'3�'�4�G K���2�3i�8ML
-��@�ˇ�R4�4(4]��%@���i�2�P�1
-�Q�	�4E�f�����@Q�s�(۠�v(�GU�D�(�%;�4��7T�/
-�Q�(�D�J�FI�Q���}�P �	� !��@�(5��EM#P�H�tj�2�(̑(3eơ�Q(3e�F�	(3e&�L6��gI\`�RP�G�S�r�ӱ\)4J�H�b!3 ����| *��>��@�@-����|��x��W;�&h�$�Tɀl@A�,�������T�y�O�y�4/ f!uZ���ZB�yC�"�/���PZ JBi�(-E-�P�e�J0���aӵ���@HC�6��Vxm����I���hj��d[�-%J78�'I�,
-,�[|�@�D�8�X���e
-�oP�~�� �����""4�3��d*:!���v`���//\��B%��
-��F|(4$;d�p��Dd�I����}	H�_D���� "�@@H�ဈ�� �����P5"u B����H8BF!h0����TEH�HBF��r�j$�ajD}�1Sp�A�GE�Uq�B ~H ��L���Ԉ�j�ar�p5J�5R����Fb�id�1f�E L@(@���K�z�HD#`N$S`IB����(v������LB�.����<A_���$�����?� !JA���(�/��I��П��
-oR�Dv��tp(�=�&r�;	8�$rg�z5�:8C���?(}16�.�{u?�r*��ě,�
-�^�q����=�K���f K�9W��?��Y���f��*������Q g�B�N�%���^
-_�'�nu��&ξ�O���
-���������Nª�[���q��
-��^�f��@6�B� U���Y�����]{��.>�|���ԋ^��.��B������-��OZ�5`Rpݫ�7��@���~�����w�G���/��B'((��9A;BIЌ�D���Xr��ʔ�c'����k�[*F� 1(�;<��-�	��L'P�-.��q���j� *[g���Ahɴd�q1v
-�4S��z�	�'"�M�Bő��u	�	�5��`ݍ�HBH0�-k�4��@x�&��!�m��)v\R��W�E�j�L��v\�� �$�&�Xm�f]�D�@"����P�oԄ�;~�!@ �{j=�a�	$��İF`������`?`��e�&؆8c,�:FH��bI�I$r̫�LjBL@�X����5��I@끵�)x������$�2t\T��~�B�JR@IT�L&����S�,�W�hV1!D�y͈�U�1�K&��7�4$
-p��HɤZ���v�_]"�D��uQ�֫�K����:.�4B�:�t�:�|Xs=Efp��)XfpLn}Lny�r�_�	d�6���h�[5��LGV3Ol���Q"��%A�1�R�w|=j�����i,Y`	!f��t�,s�3��.m�Y�D{v���X��e��@�[X�"�����T�����}0�
-?�F���}C��Hu����r�3;ϙ=Ι�����b)Yۭ`s��\��=r��)2�'��{>V�/�� ��T������ˡ�W���v��8 ��3'�����������%�f�y@��F�~!��X�����B̛���I�o!pɊC �+'7Qq@���ڕ�4E�{.�2mYJ���<4�<�₢��w�Z�5�����`ԸU�7������%���-�W��wf��!h2I�ν��s�9��{����:OB*5t�D��F�%U�x1Cd8y[`|x.��He���Dk[`�bo҄�KE�D8Z���	�J�F�K���ȝL%��������,�j$���hr�W��������\����Vk���Y��N�g�I�0O�Zqeb^\�bl{du d�ryj�*��:� k �|���A�=�����! ���25H��c7�SV��fNY��W�/9[;��m��*[���˷����=�J�R�hk��m�E��fQ݄E�0g�䚶CA%���݈K,*�$��ES�A�wS��.�
-��D�Z8s�z*�,��ܶC�m�z��� �fg�p�«A%;1�\
-�^KN C{#
\ No newline at end of file
diff --git skin/adminhtml/default/default/media/uploader.swf skin/adminhtml/default/default/media/uploader.swf
deleted file mode 100644
index 9d176a7..0000000
--- skin/adminhtml/default/default/media/uploader.swf
+++ /dev/null
@@ -1,756 +0,0 @@
-CWS	�� x�Ľ|E�7�U�=5=3�ђ�a
-J�N��d�}⃃�do��?g�?�;g^|��s_*n��=����䒹��Ok"�c�LI��[voi-䗩�$�8Qh�>�n�)�������l&1ԋ6��(�ٛ���I%�~3��PzN:3Ϯ�@�4�Y3���S�4�O�ӳ���}ڧɸ|X�1�3�i3{[v��N-������fu��E�v(�}��ʍ���d~���wH� *�[�ȿ���l�+Le�	3���Qq֊u
-�2��{�H�����lNv�͙��-����l��J$:�(wk�4�N�Lg�m�Vy�g[f c[+�`�g�Me��`ִ5�U�=G~��I�,���l|�?�kUvfP��ȋm�����w�>l�U�7
-�����5� u����S�)˘4�3mQ�0ؑ�����L'�=)3��ΙM���0R"r�1�$�W��J8=4 Y3�b��5e�|����I���2OTk�̍�b��≄Q��e�LDe�N+�|�ݼ����1�k���3�'�5��Gc5#�6+rБ��A��̿�īNZ$���΄ꄉ�mX�Ӯ~�+���s���2�P
--�A�mf_2��ܶ儀$���-�$�2Y��Jӣ{H�* \�xj�53�
-%-�7�/�X�~{9�[���B;HbaH��ސ��U����I��@|�
-EҟSGZc1��蝃�Fb޵��zg�BCS+��7��K-U$e1��Y���"�e�3Q�F����j�,���7�+H�<{���.�m��#�8-��D��R+2�����=M�@L��f	+ߕ_ϑ�l�Vf��eҷD��FJ�S�HT��a��0S���U�WD�D(���{��Vg���rE�mu�H5�_?*��y�l�&��OD�v�pҒ�E�I�W�z�7���|.��̬`֒=���3�u�CU��63	`a�V%h:a�L�}
-�r�#�6#�9Z�����>����{�Jǘ� �M�hW���Z�~~��3�s��jِ׸��l���yV���5	b
-Trs��P�|�Nu�+I�^J������넑���!=�
-۩D$�IS�-�����d)k�7eƳ2�-�Ym���U�LC��4�]�)p�$�Ob%��J�(p�S���f����vv�ю�pf�݅�mk�1�D�Q��w��3M��)���jW��+j\���ф���s3�^>e��p��Ә?t��?_א"��� ���*���=ٟP��L��ݩL9�������c�	E�5����$F�2�*W��-�R_ꜝ63����M����F�1��X˽AXr��R��v�,I���g��H��KΎ�7D�e��D�	�eC�:o��W楆�7��S��@�Yh_l5�N�'�7�t\L���SЖ*�{5�H�i��HWM^e��m�<��WNr]���ش�U���V#\T~��q���dE�@Ĺ��2W���iYr���,���(�"��fo9Eu�E���g��v�Ѵ̼�d�;��
-A�l,PӶn��Ԇ��UA�K����}&j�l���I��gE76�4>jȃV3�#��9�KNO'W�N�9����5�6$��cQymZ�'ʫ�p�P��?	ňh�P6�PUK���f�[���2`Z�&�z�b�fyM��b�!K�4C��7�����P��[�g����[�a�"�s���K���LZ˞����{|�8����Aۮĕ޸���{�>��*����)��X�y]���������������b3���z`lV��{�Xt���ۻ*���%l��|���"Kt�̩��h׌�փb�ѩ�t�6ÄL��y�(��ĳ�R�s�H�ãp���Hl��%��!��]$�a/���A}
-��[�N�3Ҷx�]-�N���U��f��F�Z iE�Q�6}ִ��m�흓ۧu���^�)�Ju�Yc��}r<���-��B\�6S �Ўy٨�����@|~r`h���(]掸UӮ)`�*l,�<߃����\��A�c��[*љ�V��	y����ȧ��4ih]��������=z���v|���ƅ�{�d:��(�,�N�۲��t�
-{&�Z��L���R���G4��S	P���^G�[�g������~�RWش{2m�y�s�'wz{^Q��g�͗Q��+�Y�?�rW�ڼ!�y�#�4]�&DҒ�V�[ةɴ�s#�|�JWǤ�����=q�La�7#c�i
-Y�ۺ2{���#+=��2j��G��a�E6"V�ڬ�e�󶤹�F�L�Oe��1�Ѐ��	Ýz'=��s��c ��ʡ),ä4���*m�X+�T)E�BCٔ�;�Z)��yfg�
-�,��,w{I��.�-�Ԉ�M�g��%o�Y#�~�U8c�4l�xQ�n��Ԣ{����D-���̬����5C��Ŵ ��YU��.��c��B�mM���y�x*�GsX��)�A�?�G�Q��Z�4��^������n��P�%X��7�O��(%O&Fm����&#\�0��C����K���M'hc���8h�=_a+�|��WN���J\�;�,B'���y&I�42���� SH���^^Δ*&Df����{�f�ji6`	�����Fʋ����>rY�{�V����cd_N'���H�,� ��z�3���G��:���κ��|u�L�<Y�)�l�{��Ea^�xA)L�@�F��3����\
-~=���`�-Z�{st�"O��pNJ�}V��=#��	ls�,=4��YU��/���.z�v-��| &9�U�zꡆ�վ��q����̑i��)�m�<xe�6'�
-R��t��
-�	n�k]���m���ƌ��-����Ü�`�~|�5�
-���Ŋ��ә4XEs-`ߔ�Ƴ�8t2X��0	MϞ��R5��@�>�ʿ�ǆF*� ��L�\&�H�(�Un7ý�f�-�^.�:e��Y��i��p��ʏ�`d���U��b��xJa��@{�W5�L��L�fvmk礝��!EA��zE
-D��8W�[mn�;�uve�OU�Ѷ��X����]�O�h��gѾ3����O�e�����Z;j1f��W睓��ŶBH�A���j�L��;����)L����>-������2n�����pf���mۯ=6e��]����Z�kN�����d�zu��B���8+:�m��|�1��F�M��O����&�n��{:��i�(xƌ����n4�){�9�s??�I�I�)oF���s��I>ӽj.��m֨�ܞ��� y0Ն���KiX�l���֦BAVvw�N�2�sjl�����k���S�
-'����@��)퓻��A���T��օ!�G3�;���]�V�#��]_��WrJW���t���z��˅��!nE ��W��;�ҞC�#>eE��M�>��c����O3����_4�*h�،�3 ������
-�g&&� -P�v�NV)Y�NLs���<�+:��6�ᙘy��پD����M���|��JOmN��l]�;�3�C}�	��Q�6����h���|��<u�5]�d�0�����:����E�b��	�ҵ�k��-t�c�U��+�
-�8e!e�������k��\v�v��#j�E۵�ҩf��������o��V|�Ρ�̓��Q�n�����v��۵9�Kj?�u�
-��d�`�
-Z��y�^8R2�_�i�U�i]������o3��2�bʬl�2�YC �O69�ψ:�\�����q���:���[;����F�e���d�`)2R�ݙ �3e��
-Z����(�R_2n�CKҞ6�f�E��
-���q�J�9V�->mm�'ﭠ��7ζ�t�6C�����X$�}a��A�����iki�f2�s�yn�B��������Uv�'L+Ϻ�HJpN:�;�y��;d6�f�F�UX_����a;V�����|3e�������:5:�����ǍWǍ �������^Ll7�[sҦeU�~�5�K���qK�@���dj�����MI��[&? O)��`��$�K��g�W����b?�k)y�TV�s�,})���9C��[�o�ճ��l&8!i�:�N�#N�;3��~�cKo@��m�7��T6��t�Ӕ�BC*͚l?q#�`��4,�����zD`�֓2�٤C5�i�V2��Z
-�SϤ`����� 0l���������a�508���b)��D�Po���kX��>�F����x�菧2�� ���y2Y:��^��rRmX����۞bc�.��.�!9-�~�Z�������HL?>�꼰���ʜ�'�ۛ�ԙ�-'�;��2i���M�b�ČK5 U�����f}��c���9p`L[S�*��y�|*m}S?T�NA@_�;5a����lKU
-�pk�'��<��V����=| ���@N=��dx.����Cj�ʨ����8��y��{�<���Y�x|�����<��gx��j_6��P.�����O��)>g���<��Si�����|����@���<��i����a��p���l�g�q=�p��V��<�����\������;h�	��[�lk��?VC���NXj:����d�*&����Rs�jn0����=�9�����d^��,������j����.��aB�?v�׸m�99����]fΊɳ��t�}�8w����B4�Us��P<����:t|.�h/�yO��<?�u;[�/x�Fi�"�Ǒ;������d��D�߸4N����
-4�M������o���?4�h\(��%�U�/x��P�+Mױ�5F�Z����\��<��|��7�1�����5����WM�ԦwB�E����M'5��D|oص��
-�LjH����/�Bh�B��Z�B��!F	�$x�`����n%X�жlal+�v"4V��Eh�Q�������ǉ�."��`��7B�Ch�bO!~'�^"2A��-B�EE�Me�E�M�ۅ>E��D`�E��_B����r�M�B�����[h3E�,Qs��=H��U��M��]��E}����	Qo��>Q?[������?�Ō2n��ECJ4���hȈ�A�p�hȊK4�DÐh�+扆��aX4,
-8p8����� G�aB[ƌc����h<p"`9�$�ɀS �N�X8�p&`�,�j�ـ5���s ���� p!�"�ŀa��h�p�r� 4k�U���0��e�2ƍZ�ؙ���}#�7n�C���n�5����	������^�,���~x�����_�<�0x5������_4?���:D4?��
-��O�;W4?��ԑh� x��*��G���"�%�_f����^C��o��&�o��1��msJ4�x��	S��}���D�pzD�G�~/F��S���)�?�&6�ob��p0,�_ �D_!�!k��~�[�w����M��80K4���O��1� �K0W�G4/��0��#@���Gr1�(x��h>>k�1p��y�oB�>��x�9�|���lѼ�N��E�)pOR6�4$9��3�_	z�}&u�*��B�j�g���k��}�x!��\��b�y �� p!�"�ŀK��R��.\����
-�
-x��O���*&<
-���~�[������� `���&�q�����P�,���ŀ%��8\}�xhG�B�C�'��1H������x�' �0�D��NB��x2\�i�)Hw*�4ĝX�pW����j���A>�v�Z���\����ľjb�% ��K�^�p�J�U��� �`�']�z �}�a�Ф�p�f ��-��VM����D;&ߔ��r�&���p�^�}�� 0�S�� �ɔ��>x0_L�B9�1x��<�	���� O�<�
-55�6������K�
-�5 ����}��	�&:ք�P7��
-o�b]K`0��R�#�`�<�H�G�X8p�x�	 �=�w9�$]h'�b���S�?M7*Q4 ��c�}���Ag V�6��?���*]����F�5���9:��|]�.@2�:v!܋ Ї:��#�����t���W�����Hw�."���p�z]�o�E�&�̀u��E7v����M}�#�z$� ���� |��w'?��.����EB�wU?�A�A����^�A �ݯ��~�C��ú8�Q]��	��ԓp!��@{~�D�����m�� ��&1y�K �ž/�}M��}��m]�.��p7R:���� � >|
-:��C>��s��/_��5�oh8 ����.��A�ua�X�"�b��R�a��G ��YG�=
-p4��2���� �N �X8	p2���񣮋�i�;= �V�<�<�<��J��*�Y^
-�mQy{@�܁��
-���nx�	���>x� 7[G����]����ad~��K٣�<��b'�BO�����*�x�l �s��J���A{؋(�1-(�`��^%�7�kq{# "o�2�Ҿ�H���O��>$�G�>F��|J賀��< �c_ľ_��-��]@�Hk�����8��(��,¶w���y���p�p$�(Ў�2��"�x�	�倓�N�!�i�LB�:��p�<��� .\�p5�Z��� 7�n�X�p7�^���<x�4�Y!Ng�y�+��H���"�2�W����W��u��7o��x���}�����G��1�,�O@���+�7�� ? ~�X��� 8p,�x���� � N� �����g�]g�s�9�<��s>�B�ŀK���ј��1wGc.�dW���<W�0F�i*^g�k��:��� 7�n��#(�i<��n�=A�wd��}A�G�@{��1��' O�<�<� @���}q/ ^��ث�x�FP��ބ�-�M���l�x��C�G����j�)��}�������5<߀����;�'��l��	�3`���Et`)�0"ϑ�Ў2�v�!���p,�8��X�N t"!lKֲ��;���Hq
-yN%t��
-�9	��� N�X8#��gQ���;��*I#��X�V���q�a�j� �ڐqڹ=='d��!�l�<�NW�悐�X5����,F�,gF�0�q	�_"��*{�s���*�*��
-8p8�����¢��� ����'��?	�ɀS �N�XA~����3P�"&n%���V���$��|+[��g�W:��Da���C���x~ظPk4�-oe��ˍ
-��T�LS�G���`�!�a�e��hS�?x�`�*^e/��2������^�x3l���i���Aol��8_������x8���`Sh;��v�<67��ؚ��������
-nE-m	�ۄ�+${g���}
-��y���W���z$ʏp�*���&)f�
-�  (�&g] 
-�i��eđ>�բ޾�W�&�4ye_���P�5��UU�wW��Ҽ��������<�/<�r[�-9��#���:_�\�\
-�_K��r[[�v�mw?r�"-�s�<(��]�K�ւ���O#	��]y���38�mݙ�G��ZC��p��+�j�%�uy����`�76���%TW����x��yG��1���\�����E+WB-jK&�
-�h���*�m�h[�8��6��Ӷ�9�,�
-[�Rf�����df�͔?�}�E��3�E!:BU���J��L1:����uSʦ����OL)�dJ��)��)����<`֞cT�Qqe��럙��_��ۿre˿qeL�)���);ǹ�US��e�n	��ȕF�+M}L7�);�3e|�)�9�+[��JK�)�0e�4S~�a��A��&T���4dUe�ŔrL�u�+�CL�v.W��ǔ=�+:�9��\i�W���)�qe��Q��C��Zȸ��E@���cQ�	�-i�0��G𿏀o����_�B��v4|����Y�@�9��q��8h��p�Oǃ�<�#�~K���t�O�8
-��ˁ�=	���m����ӧ"8�4�	�#ؿ.P�I�A����3����`l%|Y��3��W���2�Lx~?C:W]o�, k5�Оg3�I?`
-v3���u�o�[����VЯc��r/���x���X�	�,��Kٻ���=�w�{��/B�AT�|v�=f��0��/��M�CHt{���#�b��kg���_��Kz���'��aO!�L�4���gd�r:$� ��9�?g���_�3�����%�c�������'�WA:��|7{�V��Z�&��-o�m^�\���9�+��w10K�FN��=��������j�!����?eۜ��nƣȽ�}��W�g�
-S�'�(��|Uݥ����j|@�Kʇ��������~B�~*���d�砿�>"��;��̇� ~�~���5(�� �~�'�w���_ �����p�#�W�o�FU>EE�F����[�Q
-i�׮�}�B��F�����(�Z�:*��I�
-?Q{�h����*�G�?���=f��q��'@:C{��+�1�R�)�c"ViOk�hU�kʯH�_��A��h�j�ʳ�m���s�����^ ~T{���^B<�P^<��ܭ���*�>�5����u�#���ko��8|o�}�۲�w����~X��������H�|�̘���r ?�x���f�)�i�cY�'��З5�x�ן�A�k������F�s௵/@�H�x��9�W�W�?k_/ҿ~K��|��=(�j? ��m��G�?�~� �Te��3�?�L���BzC��ϴE:V}�ї �-�^;i>���
-ƛ�9u�n	�L�?���U��SU�N��:���7�@�5L�`��ʗl0��eC���@�u������y6��C��r��B�0-�詌���h	QFh�7F{�%J�����6J�,:����$돕I�[-��	��m"���I2~2��(S f�����*�i3Q�шQ�1���g�zMy�%�ϕMZJ';���6m*��i�k��fB�����^m#�[�Y��>��]�y�i�R�ߩ� ��Zb6C�SJJ�
-��6p���5o3�8]���N�.��.��
-�W�O�$�w�Z��!
-�c��?�a`�Vr�8�,��f~�F~���C�r��)��ip��8�ߒs�G���} ��.�����
-��i�)`|�������
-1��5��ɯ˘��o�p㟃{�����-8�Kp��ې��F�O���.�_������{����9��0��U�����]^	�
-��l-����w�����N�
-����>��u$-���C��E����$
-�Bx��E��a.^-j!f��1+E�s�QHX%@�n��`�,��6�>�p`_`g���k?6�0m��P��]�
-H�(V��C�w�Xm'���.�����Q=�t�X�W����O\ĥCl�H���Vl�so��b	4�
-�p�n�K��Y:��iџ�m<%���&�ʏd+��2��F��:,jA��H�%^G��?&vdXA�>X��.	��@T��?~�+�`v��8�NA��������!���#D�����\���L�R3Z��!��q�OI7
-��7�u��0��u��q�f��u����T�&��f��ɜ|	�$e�s�^�`�QԮ���|��Q�|��5���z'6oB��1u����������>�p����X'�\������U�Ѓl	ޜ�;�e���#�oQ�~����B7�J�Q�wf�9(���l	�����Bl޸��&N�
-h��}��m�z�����z���H�?���l�	p�h48�7��.,��X�?�2x[[�������(;��*U/`()D@���hTA�T��6P�*�Uc����$	�T�N1A�"l���P�nU���6N�&z�:M�fI��5 �ڵsa�˒f��Z��R��Bg0�g�4O�
-^F>���r|q�C?|��ҁn��t�����w�:��}@��B�5�������'�:��_����ـ�?X���6T�M���ٌ�:R�-�O�ي�=V�m�Ղl���s�k���I�|���X������*<*^P�;�Ң���1̍�-�Y��0pe�^H^�%�}�_�v �k�)3�$Úހ��$�ԩ$�ԫ$��,� ��8��8��NѨ�m}T�'n�o-׾��EZ��ݼY�Y�!�P����Kz�z�C����\s &���>�����ꁇ?��遂�Z%tZ���\�tY�]����*x���h�t�Et^�}m;4t�֗���"`��nꁎ˴�<����@�m �_���C~d��z���
-�wU�e��"뽛���3�}� W�����]El�2�k׀L��u��Fp7�LF#�M �p>&;�Vg�u�~�/ h!�g?W`>ĕ�\�����R(��I��#��
-�����2H(#�2Qx�y�<"H6� 4b�N`�\����,}� LHs`m\$`��0���z��W阝b����,-����t�� �X�ChUP�y��7�Y1���@#�ΉK 6:V�Ӡ:ʦ�:����0@���p�wY���i@i�j�
-!��M3��y�`�`
-����O�7LQ��<���������d�ʈ���vL��(�3Ed(�2�8E�X���(�_�uJj
-�'S^;Q����9��U���U9߿d�3P�����f�A>���d�|��T���ol�ANB��m���w�d|J5zD���
-(�PV���JM�"
-,s���$O��Zߵ$������BcG	��e�(i��b�����X���j�l����Fb�Q�ް��:��`)��%W���ة���89�B0���I��4��d�d���Pv�Go��M��j��F�Bo��O�UwC�?���ǌ�"ҫ�@��\�l����T�n2"���m�6E��:��(хFh�5�:��t�ATk���m1[���  %�V~b�a-!������JL߫0j��k��^;�����;��NC�?
-���5�6f�טKИKؘD Fz}�T��
-�<�AX�h	�c�\: :f�����*�c���H��3b����(�3�Q�FFQ��	����j
-4vjA{���WT�C����!����;�~QA�C�UM�?�?(�UL|ץ��e�{��:���졊�I����X9e�㉔�۠��6�L�p~�`�p�Q��,5�66Z'��:�H�f[�'�Ź�ů-,P�
-x�@�O��va��A�~X9�5S>ɾNU���
-rp�!0h��M�8�K��ZC*�ӫ��I	��������/'j<[����G�Tx��'jk$s�֣f��	���T�a�6�؟n"�"��2f��ɓ1S(q��U���1V��ՙ��Մr���R�+�
-+�r�u�BoᵗT��U�!ΰ�
-��*X��m� ��H*���
-�|4ˤ�z����,�2������5�y��BS�4)�X���-��C
-�/�Ք��i'�&���tV��'"�qq`VF[���(�FA���3����82�#V$�6�(�㒖�������U�����
-�P˯jJt���O�*�:���0H�r�9����q�aa��4hUS�8����+�m�iΠv�ytj�
-�:��#y~�7_G�����+���FaEqy���/�x��Ȭ��`ei�I3��%[Hl��/a�-WHL�ꉓ&H�5��!Rz�(�fb5��'�[ϗ�!�:o�S�=dF�̥�6�↷�᦮�n��%�tJn\o�(NjV� h=ˀ�ŤɭZ*��Ȗ�Zڱ��{K���4<r��aj/���AF</G=�F������������EC(:[E�N��=ڄ6�8��g��|��C��,@X#�rJ��8�W�2����:�w���Z���v�����L�Z��oq��k�@�LC+HH9	�	�& 63D�}��ޭܔ��O3��)X�����i��aN�&���C�N��W�6���Y�O`�2�:@�}��� 7�����X�$,a�zya!P�]d����r
-�!�V7Zw���>,4h���DE>c( �z��e�,�e�<t����@T��NP,� �=iʱ��!��?�����0��,����˂�צ�0�LWIb�
-�W���8�ZZb�$��%)�e8'FI�!
-�e��E&?
-��l���*ސz�z���S���v�\�;傤_��;f�W�6��F��QP�I��A�K��Srm��Q���u6������Y���z�W��]91S�*�;G�p��=9@�%�ޜ�岠}Җ�p�hX�h��A0%��]?�U>%h�ڟu�xPG�
-u\��̉4���P*|�� �����T�Ϣ~��(5��FVjJ���	��E�t�F�B��ǅ�����o�SPfw��.��Q�_4'n�Q����f��7Ʉ��=b�[󶈗�B�}+LM�k��@�۠�m� �Xdׯd](�.l��S9%5K�;�Ț{5��1���ݱ�ג�k��~���P'*|��‣��d65g���w�����ѡ�ױ�:5V6{��8��M�B�0�Y�Yi����t�I&rŀ�kՒ�9P���C����\f/V9���
-�$�>��j1���]yX�2��v����2�'@��0����s����È��ߐ���������Z�=Wڔ8")��Y
-� �w^��R����F
-�]m���� ��>���
-�j�2���u��!�t��r��H�D������e]5$��0TA@&�2��ܐ���V���~���a�tJ�@7�����f��4�=�	�c�w7���eH$�K9�X��=bd�O@��D������'r$�=%�H2|"п��HͶ�#l�Z�m�i�Px'����eF��+���2{��+�7�S��
-�K/�%q�[��l������s�K�U�\%��,
-g;,�:Zj�0�H�w${�!v�Oh��H�W�x�D`*je �D�2��*祔��-x���ze@�a5�}�J2~�]v�4\�/xE|�mHyUz��uNGt�)z�,:��FVK!�,�("�^��id���$���DnW<ҔkIA,m�nF7��d3�m&ѵj�ZUIn��:@�Fh446@r�"ՒY42��Y��_���e��`|���3G�4,E�
-5Z�
-�
-y6�/
-4�������*�<�nP.���1a��0$7�9��P�&+Tw�jJ�WsƱNeC�+ ,HC��^<������}c� X�r���9�,w��}--�M4��*��0rTL�?��D��@D��4���<,_){}��{�=�Ԝ
-
-�X1�4[�&} �����"�i�S`"��!aRk���<}�Z�앷F8��l���`���۲��I�C,H�B"��#��q�Hh[1fX��5�td7hѳ�=��a'ZO�@=�(/l$
-뜴19��Zg�Fl���^�(x�/��ӄ���~ T�'��8�F����D�RXM INc��bc9��Kh�d8�]��J��K"wT�R��&���}��*�խ�3�$p�mN[{w+�>k7O����24����U,v,.un��y�b@��:ۅ/p
-�����`<Ì����&,P0�0���+���̷!���Y�E��/ZZ�f�X�lj�8�b��f���f=�g:�|��ޝQ��̳�[r�EQn��!���}!�4�i�=�������6�uO�̰N���K��#rD�[�N�S��t녺s�Bݔn��S���LK��6��&Xl�)�K�@���M�i���0_܌#
-��^P�( ���nhU�\�LZJ��g�9H�a��p"7�3]�� v�Z���:���ր�%��a��D�=U�w� �Έ]l���N����,w_	g�۝0܉$.�S@]��Kv�<;M�]�[Q�NX���^U���=*����'��h�VRj�;h���뙕� �/��G�����$�-|�P{f�Ƙ�-����3\�Q�0}�%�e���`�xP�y�p8�T�dx��U�������/\�ۼ�		��]����}�b;��ڮ��M��p?.�µ&�`t��ufx>����=��ҷ� �9��W�ZPc��d�4�f���DH���c��([hB�(n��5�=��z�{P�>y8[>� l+�g�+UyL��Z\�á����'kx��5�Bg�
-%>�<)�J�riav)l]
-��u�?:���=��Sl�e�'�*�x١�C�Mx�"eo�B|x�aڜk��c@�&��^�� (B�V�Q+�(��1&�K^�1е �C�%�p\��%q��Y呫�\��̕k�h�2���]� �'a������a�2�>���h� �U�����$��I	�Q{��}�x��(�G�fôfo�=��㯑%&�sY��0TЪ:L�w&K�i�dR�y ���2���&����4��Wh���U�R��݃j���Z��vP�8�A-uƮM��|� �8>d�J���+�h�tӂ6�s�B&zv�����(�VN�\�7��ek1��Ʌy�u�����0�m01�4��Yo����?s��b�Q�u���A;�)'
-�e��7��8Q���1��1��S?ʜ3��|���̤������1�Zhf�7x�+Jh�"�AZ섨�_!��R��@h�bx (��	ihV
-[ĕզ���ΘMu��xboF��.��
- �GkM�,mn��DhS�[3�"%��c���+��B1��f�6�5�2�M��"�J�XSv�·�����9�8&ղPd�^f�IH�V^\s
-ӂ-eP:Za�@>�@>jj�K��Oe���ӊ��]��8�.��}e-(-��Z�30 z]�j
-��{8� �{wC�{ҳ`��-��\�������k����W$Z��M�F�
-��S���M�;ox�#X�s��!���Tsi^�Cb�f
-�蜈���<�f�Jˁ�}�]��X�c�F�t
-)i�Y�%
-@V���̮&�jc7�d�q����jV�I�&Ph��z�U�h�d��\@�� �e�L�3�~3!x0{���oz��w<��%Z{i�L⒚I|��
-�C�
-J	1��h�iX�XK�a���U��2{X5���:��%_�<+)�޲�������У�gx.j5U5_�� �s�͔��HIl�݊j6�q�!�b�J>�Z+
-
-VA�҉�f:��v������)�4���
-����g�Z���M/ 4�X0���>ӪUA�L��
-��
-�KHޓ]�2��`5o�V�.R
-Zȓ"6T����P%B�xr��
-\ǀ٭�"�H�r
-�L��������'ee�?��Ք�ǂϛ����~*8ݭ94�D�eE ���V,2�c���"������!�;s�R�y�f�@��L~�M��M��Mcd"��=���cW������Uٞv8�F��0�_XU����DJŨG���u�L4��i��پ@>��=��L4�g���a���m�fخ��������Q�j���-���� `�l��P���e��M����UR�<����E٘�k�U�zq9/.�n��>r^�F*��j�*�M�L��A�y��@L�����k����0�o�=��v�@q�Ҏ��:k�kW�7> ꂌ�ZλBԓ2��P�͋�y�uK�L��(������$HG���v�@eK�h'|/�F�u��	�:?A����9��2Moij��S�,�d�M�'����%UҪ=QU5���s�H��R�lM��p%� ����"��Yهf���|�I*5���RԐ��הV��Ǩ���C�Y�Y0g�@�vHgP��#����.C���q���X��-$���$���U����$������Y�q���SE:<UHk>�~�~�m]STU0��%�6�@vg��L�;�"�z��̖.A�-S	�i[9�G1K��P���.t��{��D1՛(;E�sr9N��h�ϝ
-jDaY
-�t�ӽ`
-������J��,1K���m��2�
-r�kV�o9+�!_�	�UW�� J�C�4��&��宭���&kEl�(b�y"6_��|\J7�^J�xK�Eg)}�s�K�*Kśru�u��3ok�y�������3��0�����h�;h�P�P�WW�<h[ՌU8"t���zZ�Sh�����L��݉��Ҭ��Y�],2��bA�����ˣ
-*�i��c�+e� �5$>C������Fh	Ӑ�Ϩ������
-��{f�<ʑ	�7�'���[#��s�Qk����0ᐪi�n4>^z�$�w��e��Yst���n��	Rvݴ��N�/�:F$�$|iMR��5�p��+��_-��W�j�s����ir� �7�1ҩs�y|�L-Mr��F*�El����"�L����2�@�n��"�I����&�*BcEr��m��"�AĖ���\*b�D�>O��u"�_$׉�z(��E�^�>��z�.BDr����~"�VĶ��h��"b�E�B$W���$�;Dl����"�R����J[#B�"�FĖ��
-��r����Ꚁo{�G%+|���>i�J�a/�wU���. (
-��&
-���j�a���l�n�@��Z��
-��\�8' �����rks~Wm��O�g��O��?�3҃��<� 1 !F3
-K���U��*�{b��x7�^&��; �Xt�L�/Odm���zА�$ۂ�T`(z��_��UL�t�) 4�W�����aJN9o��'�r��0_����X�]l!`�0�i�*�� W������X�E���C|J|3���YKXd&Î���j��4N)k�;��C}$�f�	����l���LƠ�aN{��Z���V�x�#ڏY�����a\Z�ٌ�7g���Ȼ�xĶ-@ћ 2a�[����\�w�L����AÜg
-�_��R1j@�li�l�31����W���%Ld�O��m�/1���G���봈tGy���N�Zd,�}�V�U����!lN��W�6��m|����)	���䪟��!�^�b��/D��Q6~�J��gL�<g
-��q>��@<@��!9*6̩b�b`n�ds�&�v�߮b�]D�t�f��<�t��T���\r��E�*[��Z�
-Ѳ�x�J�os@�r^6_�s��W���I_� �=�@d����ȷ;u�#�>�u.���V�#�}�AP��R� O��9��v�yt�g�}0X%�6����ow�v�ש��)
-�31���_HQ9���� ?�NP�ON��<�{!]@
-[ĢS�$���v�?���9��\���߆֜B�j��^�<������{�`_�������	J�E#�9��ED���=��K`)ɠ���=)E��A�ͺ&g��`���>O�ڇ���r���gޯo�n��e#&ȈRT�))-`Oא��P}Ą��,D�Zl���$'�b��;�珀P�WTؠOW���M��,2��eC̴�f�B�n#���Ja9܃ǝ4�gx�����nhX{6�8z�����EE��"yz]��ŧ�3��>����x�e���強��&�q�o�8�����7�n����D61�o�H�yNVfc˂�\�)��|zD���[.c��N�-(��kRe=�8wXJq��\�^�U�m�~�َ�F�NTt��t2�瓝k.����Zڝ���1,���c�+�1���ڛ�IU$��U�u�:��w6mE-���8sg�{�Ֆ��p�׵Wqj��UU��������θ��� 
-�"���۸CUI�������ʋ�̳uμ��|t�<���[ddddD��ߩ��Wx�!'�&�<TnV���Ut]�S=����G ܛ�B@	��ʸ�4.)�����p��W�K)��ȋ�.�7_����*�1�ב��`2K��?r
-u|�J	i劕$�ÒE�w��	ي�	=]"	�S~��%���:��W���'��Yl�
-��J��~�ƛoQ�sg��h���aO�y��^�C�.w��(�f4�:�+�9+�W��ح ��m@Ǵ-�'@Ї�����P�}�����?�?��o���3�>�3t\�[��m�f�}~r�#|��a� 
-}�Z��"��+վbf��񸅚�	�[���M9����-����ze[s�m����=�^�_o��!��:Ʈ���P
-d������в0�܋��YU{	�F�@'t�ع�
-;�*�Kr���Z��$�k��̻r��5�Ve���v�}�L7,[���d`m�����z����0�J��Jߊ�o��
-�* �VV0U�z/+T뽨P���BU��שT��?�w��m�gk�UvnpD��
-N�'��>�
-�)�����J��m�D�F�Q~�TϾ"�w��+r�,�d�,GJ��N6Jr�(�ke�(G���j�؆
-�+�!��	x
-q�����裃t°��	�K�H��j����mR�È1Є� �k�
-�~�������:��p�-@�"�
-%�Z!r�P6�"�W2."WPɫ{�O��ʝ�"˄�)�'��MB�f��[�k��
-�!�
-!�T]��'hV�R�����1�UB�Zr-~�@�
-xҷ
-��:�aa\'�LPV��J��B�f5v�кY��?6d���]#���0\\#xkZ��������.�#9.a&���������.̩u7�Zc���x�B%�I@CZ���b�V���]l}�f��񕧛�X.��^Ҹ&�	�Ob���|��x�}����#�;2�\F^��~�> IƩ���_�!
-��!g�*B�-�i���\����UN���V�Kt��YZ�z���j�.b�:���|�S>��k~C�}�:$�ŕ`��o��V㱭��H��e<Geltbl}F$�GW)�P)�\q�Sܝ���R޻\p/�f� ����Jp����&�{]p/�}��S��w>E���Q܃�BJT�C.��	�aA��5�����Q%����"����:���^N��4+�:���Aa����ڑ�;rp�ۄ���1���mlm�U@�1�'�f��g�6!sT�I@�j�, �ċ��,[Ȟ��d��<BSU-@�����+�U��c ��of:w~�x���v/�f���9Q�؁�S!
-E����(�Z[W���Ɍ��M�V���U5���g�	=K�RFPU��n~>���89�a`�K9~u�Oh;
-�p�����N_9�f��os��#��ǲ,{YP�	�	ś��	���%�Z���@�5p���-����A�ux���k�6'�!��������7�	n�R����ۆ�A��"�Cm���@�ɻ
-���>�g}���|����"Vb��4�K�Z\�W���$�W�*/9(��
-�5B�~�1��~M@Ö��|,���<����d�1�������+�~������}���u��~a*�3`�)��J}�����A�[B%�".A�����
-"�[io�6��Bl���+��T0��J�Fo<0�#�]�i����U������Ғ�`z�}�<�> O�dx���$�p��U����f�O�U�t<j���-N��n��G�H��ۄ���^�G��I�P�΁H���I蔅�Y���ߣ6O�r8��0���2�>Wet�*�Xv�ȹ���
-��f�56���H�N
-�7����l�>�zx�@
-
-X� �;�v��&�n���ϗ�f?����h�Q% �
-�kE��m RO2����Xa�qd��6�?�!�
-ʶ����)xO-��)���F��ؖP�уVV���~�vkq?����k��5vvi�!��u�H'�:��c[��T�b�A�G�;U�\�������M{�p���ʹ�c�	��;�cy1�Q*��T8!b5F�k�v'����J�"tp~�98�Z�A�����ǭo�BwEOC�
-���i��@Ї���#�wN4t[�"i`���Ͳ�d~���D�ň�O,I쯸H��������7�#8��mi�9�%�~���Ǩ����E����~K����L��\��ƞ�g7��"+��V�E� ��5)6	�3/���3&U�N�E�|iKܕ��̙W�yo�K�������_}�q���<c�28 ��
->H��F��
-������Rf��<�p���Z�ӷ�}%�j����O�q��Έ{	.�?��($���l���~)�^��m�����c��W�ƗH�@}��y������ Až�u�cT������g�E���-�g��4�?�ƾT��@.�&N�ת/��4��N�er�.�`A.��5���5Jx
-=�����wp�<�}�*���վ�/o������jڮP�q�0?R��h��K� ��ݏ�|��dM���j��b�����
-�����o�Ȫ�%�~�>`���|����q� Z6(�_U�>�&�#�ǣ���UK���7����	%��6�{����E��p��hh������PL即 Jܫ��'���'��K�DL@�[U8�v�U��3n���j�)�4/�'�/���Z��8�����wE�J
-&}D�~��8i���N�	|"Im��R�}��Z7�>�KJ0C�N(ټj� ^��
-'�clҢj�$V.�����@b�Bh;Oc��6�mK� �Sl��*)�$]աL�z)�]�������U0��d�q9�x|e)T/E���z�_�Mۙ�y-����:�J"�>�g	5�-��d�>����m�j�'yz���D��~�yZ"a
-�*�古�����׋l�p=f�	X�_ ��N�#7�%�F1r�X6�#׀Pi\#F��f�X*F���h,ۮ[�"a瀈�hT����S�_�[.�=�\|��rQ����r1v=2,
-1�L�-[/Ґz%���=����"˼��-�[�PCi���8���&bΕp���q�����b7��>�F��z��۵D�}���\ ב��|+��v
-�_�T��R�_+�.,� ��<<�\BL�2�WU�����Ze�te���(�_Y-�Ϙ�7Ƕ�7/}sl��7Ǌ����9V�o~�c���w�-}8�C��s��w]����ٿ��,��������hWL����/���j��J����h<�o�L�_Qq��]�ӿPf\������o�v�r�+0b�.���WZ�|��IM�mHmWI8��0z�Of���s��~�d�r^I����d ���T��]����<���
-:�=&p"H�b�j��%4S�����Z"TN�+��h��b"�z��+b�&�5����u��a�<�,������a9~Թ v�q�%P���[���˵���]�Zg��<�.���>�:+��W����hX��O4Tj/�;��{���Fc�;� �����7Z��"ј�l^�j7(�!�WMj�2��Y-r�����sb��Y�R���ԭ���X6s,��5���uIT3D��HM��]���Gc�ˣ.,�}�#&�z�	���R��/� ��'�;m¾����>F�0>ׇ~i��`��6L?�ݸ����7�o�����6��ú5���?���%\��-�^���Ea��m`6&왱A��n���2����i���5�B�N1�N��'θ^��^�� >&~�F��,��K��C�	�y��7���2
-�MpF�1J�6����J"d2�>�F��P�_달����Y/��'��}Z��^
-�u"e�;��p�����F����~p?��������/S��5��N��Q�K>v�z1s�����US�	k%�26H�������pUZ2P����;�GeIR���f�<��n4���8_��U�E��'N�7��!��I�o;�������h����>����@��im)\�b8ބ�*@�C$<ȱ�]@�}>	a~�c���D��5�s?��T_��ݧ��-��a��-�W�6O`�n�LS��$���Mq��iƓ���d�Q�$���H>��5ZUK�y�+Ґ�w�A�U;�A�U��7���H�w$�������9��'$'[H�VA��< �n�P+�O2d�b&Ы:|Mr��]�y�K��w]�g�^�oV����{�aX��g�1s���r�GY��>��������>�����,���_�����K��
-����o��[��������~����'�; �ژ9#�?ʑ}����I��
-�F�I�A vR0��r�]�:��]��̿npw	�s��]�O\)�J�|���X�C���֟H�z-�K}*�?��G��	�Y3�'����!��kJn�HxG����i�D�:O�0�;�2T��T4��6͛��ӺZ�=QU.����*f��B,���2
-�=��%��[!dޒ�t>��<�[����}jF4vg
-E,��ՍE��
-F�{V��BK,b��-�}�S�7@�K�*�H�>"�o�G�����b���D*���Hhm���Wm{D���y���?��hS��J�uZl��&��$h��9֤�ط��T@��p�m���5��W�X�Qc�'�[��d=�pv�Q�xv�=�� �cwh��z�Fg�whtv}��K�m����~�������"���o�]O�'��<��궷)e��Џ��I�I?��\���]"?���z�X#Z���{�9���{wkxv�Y���;4:��G�#<�5:��SÃꍚGz[�ܥ�y�
-�(�*��]*��P�>	M�eS�]g��ii�ܙ��q"WЁn�щ�m۟��?)�b�#���C���;�h���J�5
-�@��i�-�'�Fa��z,�$�;e[����-�w:I���*1�Ͳ_�g��EF^v�Q3�h:�Mʱ8�h��Shҡ�U�E�[%z�i��|�@.K�0<���=��t�O)�Đ�H}?�<>�)Lƌ���&�����Z~HI�;"	(���D��ӽWy�x7(�K�c0��z��	iL��=O��k�<	���yJC»�*參~�U*f�֨���Z���^xäR�i��)�4�)����z������1�h<�|uvo����o��'�6I�t�{<��_F��z����I�k�x*��<��v��0DǠ��`D�ڈ�������-v�#T�#�T@exR�zY45�M����1�Jċac�`'��Jc�{��fi��Y*�����>X ��R�[bR*M��S��S�~��
-�"r�"� �Y7N��wL��3Z	Moq���U�<���s >�#�'�m�h�
-{��6fV��'��'$��L{1����q�T�>ԍz���!�WQ�q��cR�c��c�3�z�
-/~c!�1��#V�أ���צ�����/j���@m��|v��S�r7z��E��}���J�׼;(�y�:�4 ��R�j��C�������e�
-���ְ��s���3-c����;�E� ��d�Uy���qx�_��Fc�-|������x���}g����䵫�{}H?��;����R��n�>M4�{	�z�˰�N�<'���l4������j�S�	����r��(^ ��/�@�HXW�DX��+�An���D�'FovW��ج�D\/���lsb���.�&�/O,6O�t
-�҈ۯ�ݩ�����W����Yǧ���
-�m�۽ӛ��R�6熰�E�HmEg���V���ɸSj+;����Q;�ծkچl�"��m�b%r��?"�*���Q�8?9��,o���ZW=�e�e�Rt��9e>/M�-�~����d�c*�n	c���w[��W\��Y�+���TT����>�_�m׊�~��.ҙ��ث����pŷ?�kh��>����~��Dd�2/���d��L�
-��NE�S;��>��G��J{Q���P�]ȶx�aY�fF�xD��|
-?��3f����v��կ��Y^��]���y�O��	�g����<������z��<����ҏ�5�����<����Q|�w5O��yDѳK�~�n�=�ht8~�	ܝ`�<�KmKP�
-#�D���>QUFe����e���tQ�L����/�)>}��foh�.���U�d}����u0۠�"_2P,�S^��i��`�}�^b?�i�"�EJ�c\�D.Q�^�%�%�3��D.V�U��J�2%�7.S"V�g%r��ˑ!}*��*�j?3�o=�O����)��S�c)���������hZL��[@͋^<�I�����=��Eڋ��o:����(�C1�
-�+�:޶J�w���)�
-pw5�<��^�MT����5}��?��Oj�S����?����g5�9M^�_��5�%MYӷj�6M/jzI�˚���o��~M��W5�5M]����7���0�R"ׂ\���PR�e������PbX�2����ܰ%�PvX���X~85���j�E�������.�z�M��n���A��áV�P��H�Yx�-|�.|(�/�5u���3ڸV�\��;�N��;ǫ�U�����N ��߁|��������vc�{܃��)�>�%������b?���6�O(�	?���Zޭ�����9�������/�[���0�5�F��
-~�����?R�G�D��	�(� {��
->�����{�>c�jϳ�|�>g�Z�;�"_s�͸Z�\��/C�i�`���lbз��1I�f�^�8�O3X/c�+5��+MT��� p��4M�������ȇ����ޏ�H&4e���?�����:�� �o`�3Q�*�M�ÉMDK��+�f8�m}Gr��&�$��ߢZ��!e�l�wb�;��.50��
-M}75���=A����+��4
-}Xc�+�̧:�NX�E�8a�ĮR�|	��)͟ix����wX�0��c�/��K.�o�@<���,0v��JJ�ˣ������x5�"�����cn�{#�*����z/ע�n2^��>�os��S۾�/g5��x��eH�l���M=�Ƈ������
-d��*��U�N@o���%�>4��'�
-��Ї��>��
-��@�&��	!�B������/Up�_�6�E�#���2/R��PF7����Ob�)ͻ��%��=\�
-���+_l��r���k�6Y��@��*JA�~��f%<ⶣx��c����!<~��@��[̓���0Ї�2��]�+�z5�r��m��.��i��4oa�^��k�O�>�]�ܬ��#n6Ps+��kw���o��D|��꯲��{N����x��T�4��F�Ҷ���@Οk<р��ާ�W��x{��)|��}X��x���?Ѫ��{U���nPnm�TAk3�90����Z�6��o��:Yh�	�V�F�X$�5���줛ܝt��I?�N�4�b��N�su���V(u�I���	�׆��B��!����4sM_�o�7���C����W���!��LI}Uh��;ue�N�Bva-�ᙿ'����O�sю�юxg|^:���Z�/�;f�W�$�s�3Q> ټ��'^qZ���p����g�����x<����Yu�/r���ο����{3问��{θ����?uK�=c�-{���f�I��L{���N����o���7��9p�@�gtce$'k7���!�?�wԨ�hx��<5�m�4׷���t-Xp��/��� �_�U� |��^����b�Gx�_�b�z.8�7������>^��/ݲ���y��g��q��텞Cwֽ���O���i��f?>��.�_]S�d<E�]p�(����xa�c�q�s����=�|W�)=�ES)�y�a�U��L.ޑ>�S�9��K,����	�ho��_U�.?���}�a���}��o���Hko�H������{�e�K���.���-����_�
-�l�<���^X�f�Ϭ�xw��*�s��"�.ex% �dW.]��ܞ^�*R=%5/=3
-ɥ�]=�d:_�r&��P��ٰ��ٕ�iO7ǓP�EX�|aQ{:_?u֬Y��N��sT[v���_I�C���A4X#���Ξjlj{ZV�Cu����qx.�m�9(7;?mL&�V@�f�#��G�y���isZs3�H���j��Xs&RQ:eѝ��j�����L�l�����DW<��� ���̮�i
-�Э��`a�9V�T���HG�����N��2�ަ�s���F�=um}Z	�����Z��,Ю�<y
-���9���؊!��G-�l�=��5`wTk��xn^`�ޕ�Ri���a,�#�q�O޸�3r]��\a�T�;��YF:]�i�
-����\�����1���=���������N�)?�6�F6�s���gf;��Mh��:テ��a��d{O*��ɩ�Ek9F8JpՎ1$>����@�������/e�Z��ۈs�P��.5���BJ���Q��Lw�H��M/0��S�@#<�i>L�,�5. ��͂���FW.�8�Y�]P��ۇ۩sk��D���bT�U�3�r���N��~ZlE� 0ރ�v�	����]<�&�ͥia�P5������Y�1h�9���;��U���F�3���t�5N���y�Z�o�I����$t�9u\t�`�X��&���P~A�{*�Ʌ,�6e�� gץ�z�j$�9�Q�l.�A �������x*E'��֙8�P
-�g�vψw���C��E� KX� oLv��AA`0�	�]Ҥ���a&'Y����N>�L�3q��c֜m1�pY-���
-�U�.O��wJ�l��Z�'��@���\��t�X���[  9.�~\�
-����"HP�A�K�����9�:�$���,�҉���l�vᐓ'T��8���0M�(	^�z���-����B6�M�wI��H�È,�vt˴3�gCv���ȝ[:m��:�K��N�hޝuv�i���<(�ю�O����p���)~X.�"9���`K���,�[�@r�
-��F�2�Z��Q�H�ɽ�h���y.�bpx����p�=�P2r��4,�y ��Y�Z�Bk'4%�Bd*�3��˦�s�%������ 7�\������t��%���Kd]�|]�Yf�4�ҹ�.�	CT�:_7��W��I��:|�����v�xm�u�H'�s��!;��hD��
-��	��`���⩮D��8��N���(�����gq��o����IT����l���oPqd��9��
-����x�ȑ-g����4�����1L���D���řO��S�H�w��1q�\P���b���XO��XGT�r��j�`𸠝�%��}Ҙ57iG�$�9�PКm�(�~�+'2�r�9��gB����qj���;/�"0��w\��
-(��r��M�����s�����^4�kA'Z�tWǦq�2(!�a��h�� S,�:�M�-{zI�Y���l����9݁h�o��hީZ�������[j����'l��V�j$�(�B�ŒjS�*� ����A������%0�pf �e|l.հ�v�3T�&�ņ�l+&'=q��Q���e^�(6��87�o��R�s@�i{3ޜ�� �ϋQ����P�h��Ў��v��ɢ���bB�Iѡ\�^�/M�v���������\
-7�@�5�>ɔLoy��a�f��9B(���$L��0�M�S�ٳ��TSέ��&���.:����ۍ�R�S�Uc�'HUYT�u�>ݱ�Q��Z�E�}SJN񩦄M�	�ߞ�5��w�h�AÌ�L�O�:@h�抌0eSDG27�d�n̥�W0�t���X�N
-f�0��tQr];��0�@[g�Q�1��-��Sa����Y��5���U;��^��h2N��y�]�x��..�+СD�s���u�!����b�-mѡ�F��L�����Fd�)��X ���
-��ԴjXS�9�tu����Si@9�J�C���r&��4�uv�%]��Sm�U6�~�| o-�j����w�=�}UE�)1Jê��K>�v2�@���}u�e̹����SA�nZX�V,�K�u%6]k��dh*�6;���0p�� a��XK_�9���8u)J�T.����:�֔+Y�� �O�uԁ�\��2gF� F6��x���BI� 3��Ls>ܱF��g
-��=�آ� �%��s�u�!�p�`�uC�gwQ��ĝ�"&}n�v6AN]�Ğ�z;�k�朢A���4:To��a�v���{��ƻ���!������|&ې]`-����8���:���{�j�J:�b�1Z�5�AF���ȷ���Zy�R5�:�`Ś�ZԱߩu,g�f�yK
-D-Q_�d�9��z��6-�6h�s��G���\��-_��BP�k*=��niQ��ja�ج7M��(W�ܔ)G�F�v	
-�ت�^��D-JՃ��<�2h��NH�}r{�Ts���Cvx����t��̵hC�����/��t����;A�C�<@�\4\��F�iJx�P�Ke+�	8t-ه#t�K���b�ݐ[��e�sa��2v۶^���C��G�ߌ�5�-�{c˙��T�b*�v��.�E6u��9l��'w�p"�˷dNO��{G�l��J�t5ٞ��XB�4��ײ"R�~
-�T�v�w����Nqjhb���.o��.{*�U�m!>��5,��{C��`�R�`���xNu4$���5���S�Xu��5�쨃�95�zF%�y��t5�&\e9��-!y��=rP��Sk����Zd��҆
-����p5W�6D:|H_��(�tMDk/�����3������ia�� lM��
-�c�r��9S̓�Z�����Qu��3�c)u�:AV�
-�a��׍���;��s��x��)�w�ټu��zV{��|�9� ��\Pi3�
-Y���g��|�Q[�F�Q���4uf��L�z�Վ��Re�y@d�z���4=����e�5V �fGF�v<�]Nd�MC�t�&��_��W���	�t"���j�V�z�:,
-�����)�����*ַ:j�'�eZ��񄝯)�}��K�����rz��yԑ�f�k+�:jM�A�Ϊ��1
-��s�]��Cސ�}�Z�L*E�P��pޖ��BL�g���(�;��������y���Q�u8��D]��"���4�����p��m�v� �S�&u��:83�8D�Pc�[���FTG�Q���J��x�b�nYs�]���Փ�$����s�9k>�,1��҅�$��9l��
-]���t� �L�S����d;�����!��"3��u��BS��nk+RkM{k;���!��;��y6���|&T��r�K�u`d�v\�`����3���<?V���v��R6O��bf2�
-�=���7R���\VEmڢ�xG6I]0��W��1L�^��7ɣ�N$��4$!�({�58K0k�4尓L�G�^�.\e�l�Y*�c��n��<'��!��|7��9ÒvՖ���������,�숓��h����V��,�����\�@ۏ lf�2<]����W]�$T��@g�n��i���C���e=��Vji��M�F��M>��5��fh#ϵ�qc����y-� �N*Մ�D���/�/��Bb �QE�W�Z�D6�Ń�T��D�B��{�MΟ"�@+㾜�)xNhbl �q&pkK�L�y3y
-;�WX
-�J�E�~ �jwԹ�k�<�-����Z��̰�'�;V����=8�er��ȲQ��Ιؚ��Ř���C%g6Ivގ��;��tƵa/2U+��f_mgW翧s]�O��a�^G��D>P�`T�ì�5���;�A�y�@��S���b;�xx�B��3��Q��!��%�z�3XFu��Yi�GUؼ���z����׺A��+8_!ۦ��H��9���S�Ȏ��-o=��%<!N�v*xF�Aڶ��u���Z1hVJQ~���}Z�`��#%� �{,��|���F8|����k[�*�A֙��a �6�S[��&��d���jƎ��Ι&e��2=2����2���h���<sspwWB�����pW����'��R�	��yt��#�$�J�s�8�)ohR��$����H���-�;T�8AZa`:�4�Υ��������WV��
-I\i4ܐ����Bk��f
-��<�;��6a��j�o��kMO�;�AXN�-k[�;aĐc;����6X pF+����Xqj
-B �a��x���@��Egє���S�!�ސ�)����4Ը���68���z�N�=Z���l�\��P�K�20���lw���{2l9�v��ӥu4�����:��B��sX�if��E���J�.:��Cb�P� c�*�iЊ@�22���a��P�g���Y���-`�Hg[�|p~6�zRVD����]���I (F��&WG���hu�}u�]C�lW�=v�uh7�a��W ����-�����j���l���jD�xG�j���t�2r���s6B�^�2���y���-
-$0-K��-Ң�`P�]g�׊��6�P3�t��Ҁ9�M��9�29eڭ�u�>��:yB�&d�r�2��*�E*�͗��4�j���Iam���'Cl�le�oe��1�4���B�`$�Z�R$�E�a��)I�&a=.�Ou��d^�!B3 ���eR��Xy>G������@�0?	�!3K>�R�C��>���}f�<�e�����?r�<<��í�t%�LK#歩d��:�ax�i�������x��[@�)�}@҂�bR�3�g]�	a˄%�kG����!�Qjz@~�<�]~^�m������fv�8�][C��d<ي[/�������֓Ŵ�^��_��Xa��:�+���g̠���wUS�]oaʢi��1,��LMs�i�}k*w׹ƴ���5�H��t�w�n@�V��ae�9�EC{�	�H�U�旓p5�
-3����M>��S��'O���>픹��kh��3�\W��f#S��[�{��4���p�|�y�Z�Ý�9DUt�M���{���Z'�m6�#M�3k�r����ɉ{���D�f(S���Z�$'�s	P8ŷ/
-��X�4*���r�7؝�#�2(ɡ"of|��89�gݩ"��J��މP~A��1����A�J*�a47�U���"fF-�:�Defu��+?5�]���iI���<7f��͞$xxbo��a��v)�	�tîD-uC�s�Շ��X�1�����$/T1�0u��c��h͎�W�-�����ܔ;*�3��rD��zS�b��bhC�F��d�YUU>���#�x�EJf#�݃�L]M0m+DX�2�y�юx���Y�N��\��4�i,�=����"�!7D�6���Q
-z���N���0&��J��)��
-)-Z���-<VТ�����E-)�L�8���	�%5e��=2vZm9M��h6y�ƍ����f � ��J�&�U4�ә�Q%�T�U�%]#ª7�P�f�!n���I9q����@��vre%�v7�(���kd�� �#�����|U%s&D�	1ϗ@R�1˫�b�K���aKK�`��r�ׄ�������:�����p�V�G�-Zs�~2j4��
-�32ڼu��c�<�o��ȑ'���&��]��軆��.YwK!t�c��s��|��%��Њ#{/��������.��4~^3,�Pl	�PF>4ÂQ�P��u%2mg�ڧ�i��(B���Aev�Q $����Y�8lY�@�~G�A��Ѱ$��nz_EG7�sâ��u/+1.�q���|mbuJ3�%���F@<��.k��|dK��5f��Wё��6#&|�l�b5W|��x��Y��7\��oӘ����V�����<L;�H<�s����~;���6�0IL��y�x�`��+�	UyT
-m�WBU^9ªgl�t������se��a��<?�^��~F�+��M���CWs�>�Q&k9�x�N
-i ��ђ �|�8��Ǫ
-�^VP�gHh� ��p��8)3�/����mB���Dq��9s$���z�y6M���LF�o/���V�,�l8�$�w#2�#���!�+3�A�/2�F/�ůלhh�������.T튳L5�0�*�����g���] �Ѥ�Q�I^q�7'��BI=�[���״��á
-+W.tmZT+,RBU.r$Tp��v[�E�ˆv���X�C�Wn����$�F��'s4L�)D@g�h*�􈫣��Q���F=8�
-Z�LmK���Gk��Jx�
-�=r��\V�e��1�_$V�u�	�]�֓��y"�REe$����z�E7�Py�/��ܡ�eBh��[뇴W�;��=5D]h]ot�pw��l�B��v]Yl�S�FL5� nC��\��y�8]c�D�u�)��%��s�����x�Y��=�b$
-a�4��E=@�*˸�h�j�D��M!"��0I��P�8�!�tK��<�k�0\Z�~A�1����M�<xC��*_��(r��J\�P^Pܖ�$[�*j��b�|{�P���F_�x@w���q�I�-(�P4^���
-e���^�U^Y�R�c~?F�"�ܳ%{K��t���c2Rd��5����>:��1����\"�/�-���1� �E���ȭ��� d�8��l>���<)���7k�G�]F��A���R����tr"s0í���.�����I�d��F|��I_�&�ߋ��J���b�?eWBC�0ӛ+�z�	��a�D�Ї�C��-��q&�c�D���{"ߐ΅[B���b�Nx4Z`���,r�EfO�ҤG:7��Q�'>V2r)�h���=��h�	;��}�z�ޑ��_Q�o|�����{�~TZ��k�LvϿ�H��ޘ��B�-e�[���W4H��C��ֳ��-aw$*%T�RE2�����b��C�iȖ�a����~Q�'MK���qЉ9+���C�Z���]���v�L'������j�~�0�#�9]����(�}�W:�0f�D�44U��>�XFq^k<�xԐ��/T���C��m�z�6׊� ���_��n�
-�/hKi��)%@Q봖���d���m���fP�{��Gm2Y�S����M*�tKUu��kd���	Aڧ�_L�&�ݰ~��N��ѝ�!:�s�7Y�S�SE�|EZ�@��}��͆�ef�I-c�9�B�i/2Q]�a?�<�\z1���EDꦢ3���J>�Uܔ锒�\70���e)�Bqz�XF�B�&�0]�u�6�B�\ŵ��I����D�ZHg�*o:��2���9�.jwX��%�>����(.v}.�/4$���KQ�UR�_�S��KǠe%�����Xv��!��H�))�}B����CA*m��錓��ҫ��0r��Fh�*l!/9�MQd-�}����Yd�6!���E����J�9ِٷW���	;���*���p�	��r�!���!��m��/@�J�K�t�*�� +
-o"�&�ǯ0_��3&7()��=�~(�M�ϒc�ۇ9��(/�D�����Ƈ����~y�[���o61j�J/2P���	�S��Y�?�=����8(�X����e"A��+�4$�v����JS��H�K��`�Q/���tG�Ȏ�9�>\��q�ژj��nˉ����<��
-�.f��Ѫ5�o��H���cS��_�i��u�9:Y����◩�$YW�z!�
-H�NiSƐB+��ґΦ2��i8�l4����2f�3b�#�Z���4�ԝ`o͘?q }T,�ȆotO��_*.���ޣ�-0 M�DCL���F���:
-�>-�
-�m�Ҥg4Lk�87�$#-�yvFz�����F��s��%�R�&�MC�22�m���~��Ym/
-�4�������-�I��Yf��P��L�tm�f�?T^�U_EW�F���C�M���p��xa�n��a�AvFZnF�ǸE��2^Zz�f#y)V�7ܦ��9��f�gh��@\?d��//��/n����β�[4!�h�}}
-���o*&��x��>	]G��&�Sl�ץ��Y!T����Ĉ�j΍~���Ƣ�ء�o]�/�!65����BG�g|Ѳ@�	�aD/�Ok�w$X�-�k�~(��&Y�s2B�Y�7
-�A��=޹YY�ChC9����Z%��%ވ�lO��j�xqNSĨO#d��!����d�t��d�}}�\����i����j�p��9��S��&h�s3h����XH��� 3W�&���47#�7ꅥ��5�h�)jDEd�ѤGc6Qh�$e�9I�seB!�p��%=��54��k��j3q1q��ZZn(��B�W�Mm#k������[s���F��sB8QrbH�qF�\{�S��B$+Th��=���7�j����<��[�7N�ۑ@nV3[̐�I�ߤ9��g��f5����#�%D��g��f�5��C����$�,R���se6�Sӌ�KZ���~���g4�H���d�|kӬ���?�Fi�٨]�
-3M7�4;W����,;#Z%�WR&C)�]"����Ea�E7W���8�[��iƿR k�6�O�a��(�@I���������_��2�ϕO\�
-�(�JNu"�5�t=��c]a+��C���T�a^���Jm?�[	iS�j�ń*[Q�}�DҢ�".��6v��_�R���&%��"apr���a<RԒ}
-��`���
-��r�X��H�I��2|�nH!4�!����@r<&��d0M$O��Q�K��iTte4��S�4��l/��U��i���-��E�k,��d�M�t�j)�=d��R΋t�����pZ�'2G"+I�U$���XNtdDX��.�� �(�l�%�;�c��-�.Y��8�V�����;��y�ӫ*hR���a�e��D�]X.�Ͱ���3�&'�"M�:�W�1�[g�X�֠1ˮ����i�GGtrHg�A�$�s���$��͜��"�U�h�A"�B���̭T��C�ۢ_O+�7�ҪG�����w�Q��{Źo�s(>�^�t�B�С�AWZ,^A�*���G'U�9*�e��#ϐӦ�hX�cZ3yEO�؍�#?JK�3�I�4q�+5�¢/0�-,.--�R4�<|�mI�����P�lm��$��%s��V�d�TQ��.�~!�%���{!w��Y^��H�����^Y��O�S6pPc�j��:OHy�h�(�.�u�}��M�H)`(��=��T��ѕP+���k�(���RXpD/a�k���h>����N��T��Z��F�%Ԋ�]-L��>��$�i�PfnF��;�No��~�V�lB\��>����b��_�fU5l��b�^
-�d�K�>+�Xi����[���y%����g^e�_b�^к� �ɸ�E��V)�����RҰPƥ��V�~*�lsח�G�(kRP�Y���ἒ�kt���A����0,X92�J�))BOD�:u\rw�����#eUx�}�i��3�q�H6��kMT��:�]�W��lB��;��9�o|��ղ��W��](u�Ho��<����Y3��Ȅ����[?�������(������u� ��D�<���Ű&Bf�+z�Ŧ�m��)�Z��#����tQ7�R�6P�E^�=))쑝��/�	U�x����{��Q��d�qgZ��^U:�Z'��`��>��f�^B�~��ќ�S�v���+�F64z��ϿN̵;џ�pÎ�N��u��M�+��Wm,wJ�R�U������F��К$�H���#EHm)R����s'���k�S��t�ݨm��<��Wv�cY�z�l�с{?��锂���ެ�z���gr�_��M���jgkA
-���;ˋS��RZ��(�*�*��("[=�/^��ĥ.u*]��6N|	1��1�5��ȕK����(���u�7/y��^�d�#�[�։�j���믿�{���N�%O�M��L�SՅJ�B4�z�vɴtK�-K(�K�u��[�J�uB��U^o��<M�8X�6-HU�CΎSuI�N��V�fU�_�'�(�P�1��֖E�Nq۠>�k��f9�'Q�rj�J[�����*�M���뼤�\l_�Ol.�4�)�O~���?_��4��ӷ$d���Ӵ�ς!5ӏ�Y �ĵ0-և�t�g��r���l͈�l
-
-�5��!���m���}?�+�B� [SҬE�Zh�^P&�����B�t�(����<z�S��>�g�"+ED>'�q
-���h�WA~
-��)*�/� E�jcaQF���)�INQ�#�5�u�����If��dT�u@��R�|�V^�RfR��,����,/m\�9
-�#��b���)��l+�8k/[�2w�9-��I^�S�%G4���5�2��/(.��Z!1�bˣ�3Zy�\����!����Bw��Ď/��Jʲ�)ʷ㽣�������8�|���w�)��h�1hf�ld�iy4z�u��~����FQ�¼b|�-�9�8�[/�e���b����)t!j�N���uAB�j��>W��j�w�����vԇ�5~��M	-�y������ht���&�^3�9�$�Ԧ0x=4���^�*UP�����.�͡���p;�m��'�7�7��'�oh��g�9Β|�c�a��>���:b�"��Τ`tK-�><�ƦmJ^Jt��㍌;���ϥ�b��Hi�&,��KzJiY�\�����+�GW6��Mt�b�@.�c��#7!��'�����c���LP�n�lڬyn
-^E�@'-8INтӴ�-8GӾѴ�Zp�\�Wj�J�т�4m����"���#r��
-�w�6ݥ�t�����
-$��+x��El7�WD����ɜ�.p��K��R���\��sד�fwp�;���#��Qw�;p�<M��K��bo��=�N�`��z����&x�S���	�#s���h�_�����Ӿ�.j�_�Y_�9_�y_�_�E_R���O������>�O�ާ}��:��!~m�_������~m�?��������q�jIT����[�B5��%p3.p+.p;.p'.p7.p/.p?.�j;�\��Ui\��uiܔ�-iܖ�]iܓ�}i<��#IO$��4�J�4�م�4�K��4:J��4:K��4��H�#��?IbO��=���V�z�(��u���o%�'�t	�z�����t[�Q-i���O�^]۝�4�k{�	"�?%]A���jU��ITi��v&�s&}��t)�IΤiΤ���I3�P�M�j�D���I��TE��r&t%QuL��DՑ��;�I��I�`/���𫞓��#�F� Oձ�w�IT��VxZ*v�+����RCyM�*�>��Z��A�`����!�Pu�:\��TG��K�ک�}�J��~�V�{=��<UD��V����jW��o,�2�K�\��K����TU��|��\�X�+ԕ�L��f{e���zk�Zutm��V���:X�Uu���Wf���H!6��e��l!�Vu���v;Yw�;���]dݭ����%�>u���� Y������zD=*�<F���	iM;I�S�ii���g�sҚ~���T���6�H���K����d��^��F��z]�!��7�zK�-��v��w�{����d}�>��Ə��X}"�M�'�S���6mg��KK{��fu kGK'im֙�],]��������CZ�{�ʛ���7��VG�����g����2 .���]Mu�-�������w���1�B�Z��ũ�g�e8\>a���쩦���H����na��諦�QG[��������_*����2�2a�[*U`��[qS��`�2�2�"j��J*��q�4r��iQ'(��Y��ٖ9�W������\�7:��8�*�|K�x�)�B�3q�+�,Ӕ�p_b�ֲԢ�g���R��Tu��̲�s���so�]%|�*�+���!�Ŗ5H|����������΂�{���R1�g��n�H����?E�l���uߕʖ�|
-�9X ,��%���R`�X�V��5�Z`�� l6��-�V`���v��=�^`�8 T;���=wDa��
-��q�'^�z�(짧����,p8\ .����R�¼���o 7�[�m�p��W������{�y��۩��/U�R{ԫ�@'��;�<��3~MQxWU�y
-���O���»�6�g?�X�C��/��)r�vGl<L�0{��^*C��j�����0��+��A�`�
-�p�	�����yO�?Ey��4�8���9*�`^Ђ���K�/#��Wa��:��M�p�w`ޅڼZ�(>����#�1ܞ�Y��������v�޾�[QO��@'+{����v�¯��0��=(<��c�'���_o���j������ ��� �}�>��1a��m��0G�m$�F��1p�q0��O&�a���S�O�9��̈́9��Vf�ce?���j̳�9V��U�X�<+����B+��Xle��F�.AL�J귰/ů/��r`�W¾
-�a��=T��0���H�7�5I݈8���-i�{u+ܷ��@/��}'�L�V�n`���܇��� �� �C�a��7U��?
-����	�$p
-n��̳������w�W����KV�\F�+p�
-�k�üAo�-���;�Qsj߅�=�>� x?�ܩ��?�3�V�~�{�)����PS��6V�̎0;����
-�j�J�]My��X�u6���]~~{#�M ҩ�a���
- ��� ��nG��њ��	~�@^����~/���D�����a? ���!�0p��Oݣ�[Fi*��1��a?aco�8��o���_��E�;�엁+�U�p��n��;�]�px <��'���S��Ύ��: �N@g���� z���@_���Κ��0��Ro���k��aRы�Ca��F��� c��#���x�g"�$�L�}2x��� 9}t��?��/S��/Ӏ��`&0�
-+�ng��!�� ��� w�{�} �l���G�c�	��Z�=�x�����c��K�=��t:]��@7�;��	��*!����L�߁� |P
-�� YA�p0���!�P`0`@R8&*��`�00)s,0O�:��V�A�'2�&3Ƨ0@�`&0��Ё�ٟ�X1�/����᷀1�B�xG�b����/g�U):�J�Z���Ɯk��:Ƽ�o��f`~{+�lg̱��/� {�}�~� ��싃0�k{8��$X���@�S����� ���%~�ˌ}�\#r�7�����o��
-:a�<����MY��,$�q#���R`��5�K�0@Ő���)��k������F��G**�� e�k�����$�C#�m�@l�@�m��R��
-���
-�cu'� �Tz��.�"�`er�fB���{����G	 ���{�Ɔ)ǈ'r��I"���&r��Y"爜'r��Ez��w��e"W�\%r��ud�&p�
-F�D���（��s���`�r6A��:p�,7��"r���8�%�="��< ��#x>&�	��yJ�l��u@{:��HL'"��t�SWb���NL"=��Sob���KL?0��� ��tp���V��)�Ha��������%B�H��2�F��h!
-���f"9M�&V݂�[�m�v`Š٥�������q�ab0F����p�R<A�$�S �u�i��E�s�r�la���KD.�v���`�s�ܮ�b�!�l��p�	������6Uy�11O�|�S�Y�9Qg��NX:��HL'"��t!ҕH7"��1=��71}��%ҏH� �+"���`b�&2��P8
-���`- �0u���`#�	��d�(���b�Jg��-Q�;�bJȾ���w8�Tl����p���P��O� ��D��a'[)�⨓�"n�r�	r��)"��g�l�r��y�. ��KN��d딫�\#�:�� ��
-
-�1��`��z&Ƥ�G����1<��9A�I"�����b��J��,��#B�+�����r��E"��Dd�ˈ|���(J��`��p1v��)#���m�&���0�V���]r�G�>� �d{H�=/B ������T$�ԛlO�<#�΍""�/� �a�E6($�9w$҉Hg�M�]�֕H7"��������@r��П,��2Ѝ*
-f8��H`B��9�B�%2��p�@��`&3�������Sf�Id������2�����!2�|�f��C������"�����N+ˈ@a��쌲��*7s�v���nv��J��
-҉���}�|orG_��Hh��!��G2��Qd9@i�R	~�l���������U���p���)7�����,p΍~�<���)ߡ0.���
-��\u�;$��U����w�p�:��
-\nx�G����pnw�{����uW�y|<������@G�3���R�m���OE��C���N��{���@_�?��j7�W����@b�@_3!�3��p�F ��;�(�VG��Xƒ#-���xX& �B�/Zsu���y��׽(��(��S���4`:B� f�������8�����"`1�-�X�� �
-��Ӏ��`&0�|���E�b`	�X�V#�k|�q�Ob1�����H�R7�|h���7ò��v�}�="�������`s��a����M"�)_���V/���c�+0w`ȴ�\��p��n��Z�T��r�������:�v���������Ѣ�xZOKr��؝ml�X6~�l<�1���M�}��/��&�F����b4?�:��2:�v� Lg����������@O����W��O?"����ӊ��8�dZ�LsD�P?��(ÁH��ʏ�&���ZwuS�TZv�B�&�B�:�Ϧю�i��e�S�F��c��5)�& �'��z.�Z�թ�M��>���3�N>'��G��(��7�����������],�iX�o���2`��7�
-o<�xz���h|��u
-8�Gѡ���I��sd=Od3�@�E"��D�2�J�e�*p���4Det���P�����d>��d>���(�'�?F����)����]M����d������;��)�w&�s�Bf�8�-�ɻ�#����
-�f6䒯���C�a@w�O��D��3HNh�z���1�H����uL�~l?��~8\�Q��q9>��Sx{Յ�?���q�?@_�~���2�
-L�3���,`v\������v�,���8$���Z|K��1�XQ��*x��)�+��B�-�]P���!�
-�����؛`n6��(�>Ǧ��6�lv�!^?�ׇ������[����î8Կ��'?��.U�:��7��� p��G's$q���f�~�8� N�����8~�ר^~1��y���'~o�z�����qx�VpW�z�Ƃ��X�z_iS�S�u����Pg|��>> �#�1�x���]�w/mԊ���y�[��<���j�1�-Q;���MF����q��|<0).�O��������QK��D�&���?a.�.����D�,�/ ����PF��@� ���� �t ��
-��9��K�_
-�{�/������ya^@������3��¾�E~��"��QN/"΋(�Q^/"�y	~/�+�/#�/#��x�/#�������˨/#�Q/^���_A�W�u������QiRy���s|x�������R�*�9%�U>��*��W���C���?��G���+����xt��4��S��.��^X_�0z����Q@�Z�_C��͈��7������ɿ�G��1���P�Od
-�̬���ɯ�7�������u�V�o��E�T�O�y��l��ˑ�.	 ]�t#2�ҝ�~��H�s�uyτ��WB]d��ޛ��$�
-��w?`��.�	*�l��ϻ���K]��q���ɷ"s���x��W�@`08��d���^�-��ڐ�+��\� _'��I�e�/�Є_"�@��q���~�/��耐����
-2K�O�z(�ex��T���x��y˷y�ۼ�mޗ�O^� ��0�S�,6q6ٲ� �F��`n���
-l�;��	l�e�QK&��l�9�jY�H�߮��M�|E2��p�-v?" ����Q��p9%��$\�\���o�
-�a�����)�3�,�sDz9��'���fX.R*�U���;�|�r�C6V�8��+��� ���k0o$ ��i�k�v�߁�] �z�<H�C�����w���w�h�;���|�'	,�}
-�g	��cM��
-�:�oJ|�wn+�@b}����;�����
-���?b���:r�*���2"dRH"#�:��`2��vă�&��~���1��3��1od,%:�d�ΔD~����)+�-�,$���bx.!����T�h%��i|0���U <iHtU"�4C����4����y�&�!�:Jh=�
-\�7���i���p��Hl�
-���K�ӝ�?��� ��Ty�bKg+�0;��Ŗ����H;���=M�������w��e �S"�I����t��l����������������7��m�2h��o�rh�2hė;�1d���и��|+�~
-`����V�a�[���C~��Q�_���_P�����~�Q�:��1�ǁ��t~�k;���o%��_��Z�)t�տ�It.a������e�� �}i��˚�7���i��yGOS�h[��QC|20�����C����B8���Fk��	��C|�5p�i���x�2�c�=���=Z�?�����~>�d���s�%��==-x/`k��)���џ�0, �E�V�T���f��
-&P'j5Mq8�󇒌FJ���Vz<�Z��4].a�XtT���#L���`�*
-��Ø��\�*눰QQ���o&_Mw��PC��B�"	H&K�d��.�&"���Z���W�
-�$�����9b��y=j��9��?J��c�*���%�'RJ>�Z��O��U~Hf&����E�#�s�V�>ɦ��U�-<,�J�*��!��:D��ŜQ���+&	Y�E�1�}Q���<�	�S->_̧l}��#'�tZ�t㏣EҘ+�OF��O���3=;�ȗg��?~�2�t**7��E��(C�SV�/�`ܠ�@ԗ�Q,�j�L:�2%��[z�Th�TK��H^,���l�%>��xU'ү�^%gl[�֐�b����G������D�R'B�p�PN�H� �)�
-�\�LC�����U���⮋�v�4�}��ч(V�2d�bԘJ}ӏ�Uj}1Ml�=�ԏy�O/�}Wn�#�f䫌tΑ�iU�-o��%�D]b�VlO|�#��7��[i{%lP5�4�á��zW��o�2�j��$D>tˏ}s��/4�zG>s
-ɭ<�z���g*�Q�;�_S�_��&�RAY�g�D�U�ޤ�ෑb��R��66�]�X��f�2�*��s��?�h�&d�
-9_��VdX�6�`^���`���C��:4T�gB���2�f��w�ԣ�(���hąYMs�~�/"ͫ��"O��</;pُ+����������������Wh�"�4\��-ҋF\"��o������{H@*�����%{����U� �4
-!_y�J��D�R�L3�(��W)�{Y9rF�>�\��<0�L� �����큓�>�,z���<�_=�����
-���z;��{�b�cҭ����u� 1�?��`� �2ɡ�/����s~��u��;�`$>��T���[.��y_��,��0�	��%ҝ�o�_�G8�\=,B�.�$.�u�?�څ������#-ä���f���@�,+0��K�9�t̯��^'��?pe��;`��{b��{2�￠sz����}GM�ﶊ�W�4����O�����y�O�i[�}o�Gq���U �yI�Ѓ�������}�#�5�ױ�A�gz	�:�/᜽�m���S���Q=ʆ�A�㑳��:�����#��)��x�o����x�n*��){���Z��v[���_���/�!M�7_����qy�H��_�_ ~'>ȍ�6�c?]�Ʒ�G��)����份A��w{] ?��{�E���ׄ�uo����! ��������W>:���'��v���Q�'C=@F��Ka�)�7P$^%����
-�C����g&�ԋ��  �V�5۶&�j�|�^H�s�ợ�}����*��TAЛ�Y��M�,�͠@
-�O�4
-�޽��䍞�HY��,����x���='�?<��������/5�ȋ����G�t��<$N)��9��������!,�����#G���:+�>Ѭ���!������![�����+��t�����?�����Gu���i�64~?ҧ'�A����#���}� '��r5�����b�����^��xU-��(æ�i��9���wك�Nw�o?\�����'^��3�oݫ�x���s��������/�x�^�ãob�|��R
-~[��#w��}������?�V�=^���_��|[�Gz_�kt��}(.�{��8J��>��w�zo�O�~	�s�.�㋮���s�������t�	�z������Fe���}��&�F��mM�����������=������n�����������ۏ���)<�q��d�vC?�Q�<�2����G�W�]���&��k�U����U�C��G����ם��;��2�g�8����(B��m�$~��I�vfj��a�ƻ_
-�)8R�tG)8Z�3�R0[��(���X���x'(���D')8Y�)
-NUp������L���l���\�,��*3_�(�P�R�\��b�(X�`_�_g!���O��d�?q���r���{���_`E�΢�,��)�G�E�>�����d�WΞ��`/����o�~!Y��{��9���翕�#��ٟ��d/��`��δ�I�|*�M��d�P.�S� ���,�ς==��o�$4E���`��� ���b�w�=7��M+h$H}G�Tt���/���d6d���b8^������J���cA�BbϿ�b(��35��������&���dd�2`�Td�>
-���*�_�P��s�:�<��f�hd'�IDޢ�*@����w��Y�.9.y��l��<O���`6?�
-#D*�h����"�a��)0B<ˆ�4�Yr$Jw�t�l9
-p%FE�m|4�s"C�n�	|��Ru����H[�17,S�
-��"/�8��S���B���[���/�I�v���d���(<�O�^�T@C�iBMh��/�|8���!G�O�3P/W��� ��(J��gA�5|�j�P<�(��
-�ja^ �L�*����gS�|�h%P��ւ@߅`[�K}��;�
-xTC�o�ON�Ǖ"��y�$�*?�)�*N�-�@�
-�T7��`���E����q[��^'�~��L�?����T��Y��]�À�å�Yhs-!I�4�ȑ�3Dzp1
-5��h�qB
-�����r�f"wFd!̙ó���<�<^��y�R>���i��D�|�͔cI:�d�<O�9�:�x4�?w�{����An���	ν2���D���3�*'�W�J��)�{*�i��Pi����|F�͙�l� -b��
-���A�I�� ۂ��k|;4�;P�E�m��<��r'(�Ů�v���^��5h���/u�w��C�$� �	̾`��4]6�� ����2�J�A� X׉CJt1l`<珵�A�����0,6�A�vq�n����~�}�8���~c&Z�R�`���� ����h��n������A�Ċ�,]� ��@�#.��j����K(���p�)�$ݰ�C�փ��P\�>��zr��ǯ�6O\E�g�5��	�ϯ��*�%nH�N�&j,��-�X"nV�;��]���=�E�KQ�d1y��9���g��0��b6�ap&��U<��d������Mu9
-�\�|��`~$�����jy�8m�\�ǃ�UN����C�\m���`���d��)���Tj\#�U.3aaõihn�����3�C!9�ղ@��ٰ�%r�F�6�5����,��i�Z%�ht���ҽr�ޖ��E��Łb�I�J /���4��B�2��@+����ɧ�%d1�3��hf�\�q�Ke9Hղ휓K���e�g�2T(֖��EZ%�`ټoh��J�
-m�8�#P!�F�\��YIG�Z��4�^�%�!h�=]$� ���G%�Z�xr������%�Y��u��ݪ)��MS�r;����\��fk;QN��1���.��h��i{԰��X�є��E�-�N#�Uؠ�F��hM�xB�#.��\�p�v 6�J�6Ƀ�,��=x��GzV�?k�*ye��N�����j�G�>�b����"�C�!9x)��E�@��Z*��Nb\��S���N��΀rC�#�I�ȋ]�g����K��g�vp�������'k吼Q^�p)2'�E���6��=r-�Lm�y	Ֆh�yZG0̫P<R�D���#WP>I���嵀�B�y����(���D�Jل���{K�2���3�QV�U�=K�L�]5��Ԁw-�������\�6p�6p�6źm;r'��%/`P�˴B`m$��hQzO���۠�nɟ�W�V�[娐���(�&y�ѡgY����5{���Y��ӲCA �z�ݒc���v�n����XE�	�,���r\��!d���Pn��a��	`�!�Cj'�`�6)�"��WN�~���Ц�x�6��`�M���+���j@�(nmf�
-�iװ(�T�OhK��e!c�������[�!r+��Nm�b]
-\E�D(�CV�k�q��St���
-�s��"=:M�˖�t [��P�3��r� p�>KQ(,+�g+�BЗ�stu�D��N����:��_a!>���p��<����"T8�C�:}�.Y�^�a}(����k�R�*�HV:g�<G�E���d������K �A�`5�%�F��.��N�K�W_
-�}�V}9��C]�6����-��MK_	���
-����M��M�Z���:�fH�oF�`��zP� Юd���$��N�J�Ǆ4�􍘁��y�ǬC��$3�]��f5�[��uU
-����V���w���G�w ����w���n�i�=���{�.�M�xj�ph����m�w�:�����$����^f�Aw�wYN�}
-�Ì�����'�?a�
-t
-�P�o9�t�i�JC��`#�$h$ݤma�b�`���S��r�v9�ΦY�l�,G�z�	H��@�\3��X3qt
-�k*�Bk�|k�	�d� ^�ʚ	����cΆ۱D�INo���e�阅����;s�vۚ�j�l�� �[ŀ���׬�:k�k!$�6"(+)��Z��Zx�Zb�Ŕ?aU ^���Z� ,z ��Z|�U	�b� <g���V�Y��Zk �[k!�0�:d:���7�
-���c��~�:���`r.�vע��e�E�Q(��K�ځo�: �X��W��&]�^~Ⱥ
-�d]���utp�uä/�n����^	�$[j��^�6�6��a�/�璻j8����3þ��v�p;5�3�=p�=p�=<���Ii�=p��QQ9���h��v�T;���>���`gGH����P��\�,{l;0��8{<`:��"�>H>(�퉀c�I�#l��ٓ���S s�J�i����g�3 �와v�h{�♍�&څ�s�-� 7מ�����E\�͍̋�iE��H�������.��y���m�� ��K#ϰvD���Rc#�`�ԗ ��.�gW ����/C�M�rP6ؕ�xgE ~%UD�[�WC�2{
-[a�F�E�怸��T�г�%6����N4h�����/�w�ۻ��:��D���
-o ���Hi�Λ(�����b�Ti���6�
-vC'�� �m��C�
-�-j��y�}-V��cGQ��>�h��3�
-�������5�^g���t���	#��>C��?��4�J)"�sw�>O��~���j����F���-���btz'h��6��i�e�v�d6B�צ��R�]Y|GЛ�`�.C�f�
-�r�OF�Q�t�_�Л�7T���So�<a����r�"sԾd�zlR�J;�
-��ԣ�a�3l�=܂�G%iTr9�k��j{$�F�g��C8m��n!��G��U{4�e;���	x��l��ӝ����{v�EG�����y���8K�$㑹bO ��u&vؓ ��ɀi����TR��s:H�����tK�3��@^A�̲���C�r�B����|.2#�y��"dn��y����9%�d:텀��R�r�.
-)��(�e/��-s!�7!��
-+�y�^_,v��a�C/=Np��|gY�bN;��h1�Y��^�)p��B�^���TRස5���x����Y��U}�G/X�rV[�1ښ���u�s譇\�ކ��{T㝵���Yg)#�7\&:�&�4�����;
-�����v�7ơ��y��2�ـ�zQa�C�#Lu�
-GVB�R(�,[�T��;��p	�KA�jU��ٌµ�*,�fnT���Vnr�Qa�ۭ�����vv�.w8���qv�����٫:T|x����7\���iԃ��i@i���;�&�{�}��~���fk�e.�StB-�D�9`�S��`����nr��ba�g%�'F�C���Qp�8�~�;'���4��~���Z��Y�N+���I�<�q�B�
-)qй��hS��
-�y
-�':��X8�i��PW��%���.:r�3��"Y}� x�IV
-YR�[��?� >�]�[��M�^nӚ�DI���&OR�g�+!�JtU��ŷ�k ��k�\��\t�����h��7�t�[
-V�v)�����6>H��wS�tw��������p����і������Hp�s���� ׸��hT�Un��\�{�,�g_�� �v�84��ԱYy����<0�u�9j	�Gf#:O�Nj䃴ٝ��NRp�3�܋�ҕSP��N��mOs�a
-��-P�,g+X����9�*�5XC-����E����n�⡙���G�C�G�
-�wHü����n�[{eGԤsb�ιd��R�W�r
-'�4jw�sS����Gx�h�ͭ
-����u�t�]�]�(�@Vr�&Y'��1_�)��[��`j�BK�]rW*�X��2��n�y�v���G=�B���L�K3��ԡ)�r7�U�6:�xu0������q7;�a�n��[0i��w���ӷRM)�9�u�큜K\ń
-����19�����M�v��A�򼽎Z5��v�hs�W��\�^YW(s@�l�����To�do�C��y��L��{� ���.��>�;8�;�(�}�b�x�Ή 9	�L�`�w:��d�{g��Vd&y���@����.��� �KJ������^�"�AG�y_s�}��=㲚�+`X�],��.�+�
-�~q܇7Vx���`V��b�JDJ�{����૽�(F}���F� <��n����C�^$,ۼqQ���
-N��`��+|"JwxGq|��MR��
-N}�75ꘇ9��q�����x|:�7y3�3��1Κ=V@���YP�7�7i.��0J��DNyb�����7ʞ��Ǌ�I�)�2=Y�:x��n1.z?v��8�za��ӛ�t����Cڗ��~��W�W�Fh��!�,bfaWY�l���qz�覷(Z5���2�x�bq��7�/��-�*O��Go~�=�/Um.�쫏��:�.��ӷ�>t{}rj��r�4���-���z�h%HG}��c��*J_k�n��뀹��(}�A����5�l��F��T�j�>���g��jd6(H����雋�>E�5�5HX�f����H��L}���i>}\�����ħo�|�~�O_�uy�'t���)���WEբ��EN�t�9��O�N��=��i>}yqا�0j}:�V���s�jt�O��>���t0��o��l��C���ft��G_~������O_S���T�?	u���h�_����Z���(��E_���Eպ.A�����oW#�CA:�o�黭���`v)���w���O
-����C1�����B�O�&�����a>���t�_��F�4}O ��w����V���-��3��>���{kл]~-����3�:�h�_Uw��T�߀����Ya�OK�����B��Y�ӧM��F�D�N���(:���M��}Q:��4�D_���h���
-9>�^V���Q�N����t-P�ӷ�}:��.�:4'X�?
-�1�?�f���|�4�ȧϣ����]�߂w��>�?6�8���#ʈ����>���cQr��!���q�?	�҉M�G�{:j^�F竅z�?`^��l�(���^n�:�g�Z�G<��J��Wm\��
-pJl4(FH�@fz�
-t΋ьL�e��7ob_��,�6;���I��vØ�Xn@�f��l~�?��vi,�U��8���9ϲ����c �����$���cQL�,~�:�XI�
-��&b��qhw��(�����l4�)���X���9�o������<�[bE��j����DNU�8��`���@�[� '��c�
-�=����b�Bw��-vs��K�ژVJ}�¥m})��2����!XS̬�}E��t�[��E �� (X�
-ָ�����l�k�Yk!�@l`Kl=��W}Q��Z���X��<�&d�6�m<�
-x,�X}:B��3ۂ.nw�c;T��_�]��#)�?�I�p�����=6����(��ۣz��/�j^��t[B����pu�����U{M����)���vs�z ��/���=v�R���+������3v�xu��Oc��{�}����s�/�_�#.�� `g�1q�.��<��:��']=����>8�0��	���;���[]=�s��������"Oਢs�d�wھ��6�~ߝ,ġV�R�^BS�(���:-Nmw���x5ف&viЯj��e��A�_v}9*� Y�1264>@�C�djhF��
-dn�8@JB��(T KC��2�&@օ��:�%@��v��PM�ԅC�
-4�F�}��P�H���ӡ� 9j���� �� �Bw�+4LW�==@F�Y���
-�����1`N�G�K��	�2L3�C�kr|w�y��<��[��Ƿs�ZǏ�{�Xx��ˉ�����s�iUb� x���$^���!��t�%���5h`2`�6�\�A|�Xh��M�"��a��ܔh�*\^E�,1q�&�0�
-3n��1��5���
-"lN�-���;O�r�("/:���;TKyB�
-�xc��+Ip�'P��*�=
-�C"��c���3�	�=��D�/A�%/Cb̖b	Rs��"E�gi�J$�Aj/��s�j|ZHc���Խ��r�^Z���4�g�����?�4i\��"}lR��C���?�������"��O.�~���%!~	����x;ҧW�x��o�N�،c	���+H�lo�_Eڷ!į!}�9į#}�p��@��D��D��l��B���!~�s�!~���C�.���=���.�F�<U��G`�C�����aH?:A�Ñ~l��]�}|��?���
-u�����X�k�/�|���OT��y�}r�ο��O��s��i�Gc/_��F�|�S��H���7!��0Jc��
-�zd??&��~ai�Dc�2�/ ��"�Qc_Z`��k��e�k��_���=��ƾ�`�i���ԁ
-4�" ��e��Xc��� "�@��s>_d.��� �x��)�W}�^c����O��������g�,�3c|������/�E1���W��X ���[c������#�K���1���
-��YD����?�)܀�pJ	�~�S�˞(4Rʈ�/�~s�K@%��j^����M)�5u)��7#?�yi�E�œє�����
-x�qwp�����6w�9���s�����t�p?������V����O��go�v�q�:�&��_<�}��+�>�>�Cj	HG]4�kj�ٚ��/���
-MTJ��+e�,�j�j��I\���x�K���7��w5�~Yq9��Ju�Yt�zl�o���I���_/�q�'�A-���=���kp%����!{Bj���~NN��2�)x��j5��´���^��0�I�ٛ��� �PF�z1���C5Q؋�����ۣT>7�M#y���,�ŽpVQ5P�V�W��j"oj���_�v��h�Ki�j����TS��Ck���Օ�/L�2��W�?��Z�����2ߧd~����[߫�=>䰟s���/��l��-���x�WE���5�M}+��}�Wx� _����X�>���XM���2�8�0�������+�6����+��)�cO+�[��ځ�|ޟ
-����O�"���/��~q��:��wtUޡo����_��גx_�	�Ǎd.�d.IE���z�Tyַ��/�Ɍ^�K��"�^M*M܂O��!r
-!���WT��(�n"鏽�,V����v�Zt�$L<uD���������VD:��aFy�n��[;䜟�Mj�Y���j��Nu��p��pSz����Y�/;�,Q�xgZ&[0�[h����l�6�Ǉ��ı!�QMUq�jpT��8�^�ju�c/�g/MϦ8�a�ج���U�6	6=i
-�'7�CF{�YD�Z=,i�Q�Q=��j+4�T�g��G[���I���c���y+�T��T*6��T�ቖ�����(�J�ר��!%{k\�54�T���kc�Q��O����ۗD�������5�5�{<�%��.9��o_���(���q�hdv��nFd���8G:��+Α��$cw��*���
-WI��8G+ɨI ��d��9��u��9��:�hK��s�V����qj�1�1�ZiR��K*�~o]�p��>\���"��O�-�4e�L����Ɛ�/������(�e����(M��}r�����
-��'	%���I�^7RKT��Ҥ�8H�$���ޕ��x�����.�C��׻�<���\��lQ�?T.	Z���k���p
-"�+>Ok�}1�x��j��ߕ�m���^Se�r'nC�Ȇ�Ƴ7({O
-��W����t�c@�0�Nu�瘨���9��(k�c�)���D6<U�S�T�z�YI�$Cn���H�3�⧢�S�f��I�P������l�oz3�Ή�ތڛ���8���U����b��mN�gyrp3.������F|��^�U����7����󮙥�2�2`(�l�U #����eLZ�ȶ��὞̾7����{�i^ϛo��(��$*	I����@�]b�о��7��2B !	о����'�ͼY�����f�Pe,'"ND��8�ĉs;�L!Z���$g�<�#Nd�D���SB�[������,9|;ua�֒RZ(%�GN�.`�uI�P�K!ivI(�	Y�l�$ Ȝ��<�iRVی����6O�NA�F��|�Ԟ�Rn�ɚ�G�3�����͠�a��1Y%��ĩ�"�[o�:\C�:�4h�J��E~�Dr*6�/iDr�mflC�|�Έ�w_"�8�,-�C�S����Fb�7-��S�����[q��da�&��&����^����
-��k�+e9�n@��eI#D�ȏbP�n��B���@oN�vb�%�;h�9Fr:�X���j(`��"[m�8�H*X��#��H��l��$
-�XǜL1���ϕXY���-����bY����ۅ2��r��Z���.
-�ҩ�c�tՈN��A�7�N�͠�~+H�Q�� ��
-����m.�fH��۵��o��o%k��*�����d-0J�ĉ���:�;֍����(�r�щ�(5�S�������?��r�(�Ϝ�6]$����Z�&�
-xX�T�-C[#.�re��c��A�8f�\#Q���B��K[���,�{�7�p�6�w�@b�����9��)�68,f� ���d^)?�IuT�����Fg��\�P-\�x�³ͻ��b�����#S
-�%&℟H'��h�^����5��X-9���%9��!�&��:0�1�.�����/ȸh,������:
-��h-����ur|
-	��X�Ȕ�$��*�'�"�y�_$'+����n�տXi�
-i�Q�΢Q;��~��.��t[�
-�~]
-��2R��%R��'T�������R��hQR��m!��e�,)��C���^�h�p�LT��
-1^ݬ��%�PJ��1\��4@��
-�##�����΀�	#��T��A��o��۩P��r¿Et��
-�㖪�^$��Dg���Nr���?E�����?���	�y� H��Z`�;�:7SU"�.LJ���x�r���}YV��y���� ��tEj���	��"C��LJ΍ԋpJ#�&�{\k���NU��Wuܜ[�
-/�xnTK��0�֛01-W�5��a��y���К�>N��}�����(N�!�=���rr>�^n���k�l��I�r����������z����Җs��P�U���M�-��T2E"ޮq�ϋaV�sh���
-��,��˿G,-�o���)��s�
-���à9
-�(�
-*=
-$�p���xAA���t�_?����7�+���F0=Es77�a��Da��`Y ����S��^��V
-�}�-�٪V��֠��>���$:�S�+�T��I�)|0���2iԸ����5�����%O����C��I=�j�0�K@d��
-E�e!v���-v�!�W�N�#B�u�l=k�᳆��LT9�$RP*m���<oH]�]TِY��]c�d�JB+�4�j��5pDxչE=0h�su7��/� I6�!Fb�)��O�LG�C(!"�E���6�u
- �h�.@���C�}-(�`!�ZP���6���PM��t1�6){[�C���l�!�~.H;���2��B�e^W�o(�U�
-�)��R�*�J�v59M!�(3
-�}�qin����Ǎ
-�7*R�;����'i���ȋ�P$ae_�4�ڡ�'����%�@g��K/`���w�4��3?40,�g(�j�Nd�㝊�dl3ǥ�H2�������Ŏɲ���ː�aR�i�A�?^H�T����ҏ�����s�u6�*^l�T	����^,EGQ�w�[�qA_�hȧ�E�/Np�1Pմ�ַ~�����}9}%��#�6ʄ��&�0v�!�T�U���9��r�L�S0�N��g_�r�RHo	��Y#�K�^��H��CKe�Fa:�DD�*���H���F`Bk0��)@Lۻj�TZ�f����<��v ��K�NH(�R�;�=�v�B��ӹ$G��b=�
-�����;x���t��l��qU�㛃Pq��;�ٴGTv���+ت�6�f��'�`��No^��1:A�Ȍ٪�_	F�{��#���nTg2m�������A4 �9��_	:����T(�p!�X�TH)/�P���4T���JEha�����1Q�x*Yy��Ȇ^ȓA
-�������g)V�8�(k�*��"�f�XE��:\k����J�DR���fDߌP�3��@iJHo'1����w|���-#�-� ���8��yŰ\�E඀(_�����(�_�js+�>�=
-E3wP��������ӻD�ƙQ$�d�ۢ|��hE� �tu�J���P*���6d�H��n���ڗ
-�q�r�i����I��b!�R�luf��<� ��ՄS��*sk���*��j�f�Ws�����G�S~�4��������F3vßp'7�$)�^J�b {�D߉P�c���^K�����?V`���{	��F�M�m�h��'�s��QJ�-C�$LB�)e���*Np�R��1������tC��i����k��Bb1�:@5���i-h�����\�񼁂:`�G�oq7������\����㱷
-�}F@���"�g# �b�1�Xn��o�5Z�]#��3#��2���*��Y"^W���[������I���d���-�!�� >���d��I�g�A{�O��#�P[a�-a#N��x4������W4d�� ���(���r��V|�������g�Yɋ�r_T~i�NlI��3���ş
-�|���!����.{:X6c�d�"m�f��-9�0�!�y{��Gi�1Fo#�6��oxY��\J�#{�D
-a��\��ì?�:O��j=�p'�S�n�j��M���?Z\�����M�1��pm����`����.
-l4J�PK������I�|Tɶ�:�T���f�##z>��6߾DK�9��ȏm�f��c��a58ẗ~鱏S�i�]���k�F��ON�>-J�1�"tΈ�o���E�a_��v%��a&B��"�K��J�]2���5����v�}�jj39����9�n�O���~B�&�v�Nkӡ�	��Q6煕����u�x��;�0���������L���Ȑ$����=�V�)�t�[TlWx�
-4�'��z�B�y���D��Py\~3YMA0��L���\�tr��$e����$��#����-$��D>O�!Vl���M����*;�7�k|z�/�i_\�ʡ���9��L����#��(_i
-��Y����q�C��b�4��/��P-�OJ��)�#�i��j6����
-� N�==�E�����
-#�A(If�"0�U7Xw�5�'�hXEW���a����u"�r��E-�Z�:U��0�w�B��Ft�LY����!1���>��F�g���ç08)/��osY9%(�uC3��z*��/\Q�yNvK�bؚ׼90��yg�*��W�5x��@�:�hV8�
-w4����3<r��x�${�L~�3s{����W>��K��%�J�����U��� ����^�!�;�ཪ?�)�C��8���l�����2�"1���hH�yH����(��clA����(�^��d?jZ8�>6p���V���~��YPS��3̀\����ܯ���J^Q��V��y�/�p�ڗos�Y�fڣ<߲��_ ��[�Q�3 �m �����o|D�X-x�Vw�Z�6o��H��V��2e���{y�nSa����|�т
-Ӫe�ei��GY׎��Q�:	��� �ˌL�d��{+2��k.T<߰K�9�t�����C*^�)��٥��G)�*3
-��~ϰ'k�Gj2'��u�VV]��d�/G��tw�.L� ��	p0ˉ�+��(x3����
-���U'�4�X��Je��$G���V���DZ�k::U�E�\n%^�%���c4x�r�b�W���j�sLN]�\�/��VM���Mj'�_�=��k�;=/
-Ώ�3��Nv���ܩZχ�6���bχ��s�lm�]�>_���
-�sű���}��s�8\�V�hE�V�hc��؊���05�E2iɗ	��Ux}���J|D+�d��B��Q��\�MuL�+���y��������ѓ>.O���H=����}����?̡��h�@���;t�TVA�J[P%oA���8���X��eԺh��P�/v���	�ue�S5k@���-����8O�O`&�1��nQa7�s'���
-�����T�Ω�`H���k§�j�ٻ�]#��,TT��j����gT��7�Y�\�]%ܷ����Ҁ�R�po)����~���*��S��pVsRQi�L����M:rx���Ӭ���{[������ ��8�j挜|�*g��C�Cj���);D�,9k9$���:t��a�r�W�SE�َ�%Q)~��%9�.IJ?C�O�����O�v�:p���Bz��|}��}s�xΈ��L�A��D��[�����4/q/�WχQLx�9�Y
-� U.~�Ī��*��$<vUHʮ
-Ѻt쭸�Q��!��ثC�����ȴз�_(����-�[�{QQh�)7�[m���8$�87+�ˁ����T|������l�7��aMI�4{���k��F�e-�ɏ]P#)�
-f�T�u��p�Z<�H���]R��W�҇�uaK�Ia�G8DK ���ּ�~D���|��([�I�)(Ց�FK��u��W'g�Qs�46
-GՍ¡�nu�8�w?����$	�V/��؁�,��$k�*�qm���[z`����R���[���
-w��8܈{��Rj췒�+�M��T��vB��=�	�KE�3o�:��g̸ŋ����ՠ�_��|I��g�
-�^�J��U�'':�X�0��s�z>N��Ǵ�cZ�ge���'ܚ�F��Z>��Jp�1؀F���)��ث�+d�:�6�Q���iWa��5�Cr�"��nhql� 0���9���*��.��5��;�e��q�����^��a�ʺ���m����9�������\W����NU��u*�OM�
-#��0�K��(î��;7(`[�԰�D��~
-��}Ϭ�*`��0������+K٪^���ù
-��Z��=�*$�<#y&�|$
-c��U��񞽂m^��[��J�#F�s�˹�z��E�y�1N�:s~�G�oO��Eg�������a�Tv��p�-�l����}���G)L�G�^EB�kϦ�"�a����%�O<ミP��B�h��z������|�
-
-9gk0���JΉ$�VV�\�]&'x�L�&ල]��6uA'u�n�����3�R�0��m4I号a�yY�<8e�e)S�ғoϚTgkR]X���kRݵ&��B}q��A�ö(�T'����8Y���c�'m�Bh�`�Y�/�ގ����b��&;E��p=>!J%H�S%�������g��e�?4i�E2;������ }������,MN�U���%fj#��35��j��6V�5oܟ�XWc�dT�oK��Bl2|�v�o��o��� �yY��Sy�ٌ�!��v�2� �`�o�q}_UlUT�d�6փ�}f�1�Eu��:�_���Ⓢ��p. ��P�"޹�?�����������y~=7
-O�*���o�,�U�5�y�����;a���pj����/��Ȳ!��p�'n,BJ��N�_��9{	H��xl�50��U'�!�˙�縲�:�������]S|��.���.�L�.�LwA�Eb#�-,�y���h+w�Q�+gK�}5y	���\R���{����@(���bp���z ��%�^�Q�5�j/�5�m�q%HO��㊛=�҂g��~�"y M[�Ԯ���Mu���	A�ͺ���Fx����bU��:Q���l]�& �+Հ�¸��Ԧ�E@!=]ot��&ڴB�M��4�	
-<��r`�n?�Ft����:���Bz��h~��m7���*�Q����$ ؽ�Bz�Ζ�p��=�M�T�B�*&��RU��<UMqx@wzEw
-�Gt��V`�&���S�$�QU�G.�ä�D
-�/L�p$���B�}8B�����nӞ��v�M�D��D
-$�Au~C���ehN�,�4~G!��@�5<�l����ޤtXD1����
-5'-c��tz�%�X�0��V1��e�����%��*5����70 c�Y�g��x��	�C��ج'k�	�ɼY���ӲZv��A�/�w�]����4�\hh�.��$u.7�G�egL
-�U%��A.|K���>���ر�/E�_�I��vBhQ㯫��H쇧
-��3��
-M߃|&��K9���O�اj`��OBjyAٷ�:���Ѫ�*~ !�JD���!�Tb�p�3��h�$u{'�C��a�N�q�;��>p�\�
-@����c�����e���̀t{�3 W��K���"���w!���W(����j����\���Zcf����t<��뤱� �SZt��7us�f�U�-�Ƅb��Ԭ7T~Ew�?(DSsP��K�������i���!a��h�0��3����2�H
-�׉�j�0�*{_����*���R�b~���gՖ��س�2��T&��o�3���T
-ȫ&x
-n����
-a{�1���!��G�;����z�լW��X����q�k����76U���Zy\/�pR����/b³n=C�S;ٚ�_ 	�����K�J8Y@���
-ᣴ�V]Yu�9�Ը>.��k���e\+�Z�fO�3mGd|����>�ݝϭl'���4�w��Ǟ�����t�x#=�Avfʡ~�u�*��wG؞��
-�+=V�z*z螉���g�BML�
-�ۑ ��Z���P��֊Th�뿩���]�0{���PAy�Vc���[G��|�/h+l�0��;܏��I��&@���X妿&sm]�mWS�*}4��RZ���AU
-}�'os�b���S�U�xm�ڍ��9M�'�&#�U�:[F�V���B�
-����`��Tcu&�
-Km ���D���]�VҶ�/�]Yڗ<m]�r���3E?x�O�]�	5>?�%Q&��h���VC[[�X� ����։��QVS��Һ����P&3�-�@�U
-�2�V5ڙV��I�Zu!UJ��V�����y�� v�^5ޫc7#y	~��DOhlO(�Y�˞�N��1�&���A��Z�k�lJ/2�YÌ3��
-�J
-�qs+&�{�~k����ׂפ������� ^1�0�񽘎�Ř���Z+hZR�
-�$�!tfO�L
-/G��x��!����hӡ�ޙk��xI�$o���F^�֩�塱�i��R.��7���Rk���j����^W���wc��u�`��
-���Э_c�p�x�p�g�qx�{�w��XV����,�a���ش�^�����5�%[�j5��N!��^�x[����X��C�M)D��M������ʵq�3|��:����ֶ�B�A]�*�ʪ����~���a��i�g��僳z_>:\p��~9��e�O�7L|��~���U�L�ׇX"ئ�#���S�7N�+�`����4�Z>��j-��!A�m�Y��p$�C�)r�~��@�]�g�5�AzЮ5�W�=�����▎�f���8��{{�j|�44ĠF�xH��[|��`�Iz�!��xN#.��}�A���j�����V=_t=Q����J���*7��>�1���R�]Ę��'ZX�狸'��m��S�R7�7����O�IMQ��3tg�!��o���Ĺ�e{xc})$���/���K����K��؛�7�eo
-�������4W0_��l�o����v�:�/ݯ���_��l��䭥d��s�ϩ��E�s��o�X�K������]��ėHB)�^+U��7����O�)�>% �}֊��B�NS�#�-�����~k&><@
-�)�馨�o�����k�LM:����v���4�si��������~;0@�X��<c�0c+y��3:�R��8]��^Wr��z8��9��]��,�����COi,�>�����}`@�灁��3A�Ru]1��X��	>��Ԧ��¶ j�����{Cp&(nH����H�T 2W�+��5A=MJJ��w�$H�����
-*e*��{��'�����`��rW0'U�`0��h���{��g!t�U�s:�a���3��Sqf>�]vb>��o�T}�*��Gpt6��ԉ���$����颭�N�
-Nŉ:]��<��Eg�t��\��ݶ�s[ӵ��f��b
��K���a�v��0���k]���W���NC�#xsh{]k܊K6u\ȏ{.�O�r��hvb��7��iX7T+P�X�m!��Ҿ6DϪq6��(&1<;S���)�s$�ou��
-�.|�J��]nT����Z�5���3�Ċ<����Tm�}
-�*7S^U�/(o��� 4�b�j�U�u$�Y�%{4�P��W�'�Y�%��ۭ%W�w���U�Z���}P@mQ%�O6��U�NU��K&�ݚ�#�Z�Ln���SH�m�
-!)g��c�1ݚC�\���m�6V����X9T��6vjc%����6v�x
-m�T��z��q��&���S���	��/D�֎P�D���4�����4g�"�G��	.��p��BTC샐dmG��|,�%Cr�=�P�
-O���xj��%.b��|7w�_��-���{�s�-w���m�ݏk2�8��~b���� �
-X�}�FJVMxE��"��+��]����
-��ӵxQL�3�b��
-�1������'�f���MZ��5�(�-·���2�U��-��9��3��&+��9�x���!馺���ў�]:�}�|��o�½��V�L����4���R�-ϩ�����Ɔ���G���I��G<��J֞�U�-��ɟ�s��� �Z�=Z�3�G?��S?������XC�ܝp�k�9��>	T���3^�w��@{x�/��E�]�z�kÝ�.Z��@W�8	��{��{��jS�O{�����$|�o�$whNz��.h�Zr����z-�As�4)�Xn�,��͊q��U� H�53{`���}t��~¼J�	K{�o�]��E�S2���û����>7}��p�~�����F{��تŷj~v �1�J�کA����3�Qk��~�l�ac�Lk���w+��U�~U�1|W�wO����G�2�i�w����2�h�s�gx��6���%Ljy[�ϋ�dm�`�J�ȩ֋�g��ܢ5g�h��% �X�1�Ek! 8[WU����6w�3Z�}�wI�	�0i�N6D�c�y�$y^΃*�m
-�)"a�Z?�9��
-��u"�(��c�eNp]?�Z�O���S�Vr0��b�.w8�9������XtH���I�^͵����]��&��*a��xx�bmЩ�T���t[�S�l-u��V�]�V�p;��9<�Ó8<��C�ƿ`�/�(i�� #��3�f�rq�h�L���i�q�׶|���z)�1�#q��O� ���DwEnlw��9�8��QvU�	/R��P�+�~���o*��'�F�:f���_&��c����q�׉���=i6ۧLڼ�[��ѝЗܫ%����c����=�ߚ>mZ���-}Ƥ$��$��N��6[Uj�A���QU���Y��0��K�7��UY��p"�Uڪ�@��gM~v�ͺ��߼}�$���b�=�k���E3}����;g2����OM�j�uDJ'�_�h�q�����Xηe�����[��_���#��UY���U���وTUyqZ��*S�)��oRA�� Rl��~���4�6��gw<%�K���f-�Y�.x�����8}����ԋ��_�i�Wǎ��Qc^�J���������ywn��PC�\�u�B�a���Z�3"
-��v� ����
-f"[GG��l�=e���=�w��]Y�\��߽ᆒ��y1 <�!����"���0w�5v[]�֯�����\S�=�.�̰'R$`O����{d{2A\{��R��j����Y5��=�4I�EJ�?E��Mu�U4�����w0'�����J�}5Tc�����j�\�{���Ò ڢ&ꢏ�ֹ`t�]K����l����c�O/��S��I�`��0�2�g��wp>�w��w*�{ݭ�Q�A����+���ݳ#yP��P����d�'s��L�"ه�׉@�~�.����͉PLV���/T{���^7�O����?��s�S��rMu$G����-��@$i�C���"R����5D=3�F���̨s���Ϥ�C����C�@����?dЛ�O{+��E?��e�g0P����?�M�G@��`(�IDh���*P������6MQkj�}W���b����G��
-e�$�QU��[�n��L�TE��S�7NH���t�����{��I -����&SNO�k���:I#J�e@�U�u��BB�t�2�G?��zV}�ѐ9��p|�>�]O3�!E�������u)5:ɌN6&�R/ϛbF����}h��������WF�J��M7�3�+��}t���ft�:L�cft�p�:����2ی����ft�py�WF��:��E����Ft����7�S�h���f��f�I3���>lD��D2��f�#�E
-��or�^�
-�v�����"~�
-�x���.�v�`l�2� ��}����-v�yà��jh.��s�@s~9�OF�k
-��m
-~���6���6�����Қ�w�o������*��������o�~�`w��~Nzu�Zp��X��1���}�s�>�#�`?��P�M�Q.w��������$�Nq�i��*�t����Y���q�9�AT��ҧT��bƝ��̛�ԛ������_1�\��&{��([���f����m�v[=R�L;���'��3{"%�ؓ���dJzǴ�P��۪o����fcj=���!
-�b?L`Su{��1��\��{��H=��Щ��N�1��������t�a0��А9
-d7
-b�
-H?<��ˑ�1�[2m@�ҏ�c����3W����}tl+�v�`l�ېy �v�:a{��L�|-��#G6~�f΃���˚��o���=�ϴ�Bf��K����g��Q{u�Q�Zk�n���$ݚ���œ�ǽ�}����2�y�^�И�*57�M��E�a����ኔZ�%�|��>�_��D>�o=�uEU�q���^a�m=��o���1��z�	�����ȱ?�K��_0H��z*��h�d�]#�_�_O%�=�l8ql` �����D
-�B�.W�}�����
-��"���ٽP=Y��P��X=]���f몮�����LjM��y�x��U���&��<12�����Bz_}��z��r��)�J�'G/�m�zj�gz�CxN[Bԧ鸄���������V�N�c�qs�t�s�s&����9��g�"���:�:��t(�qt��� ��>���_4df#g�P��\W)����� ���&��A��0�_#ٟ�R>U�\�~^��k�~n2�_K�絔G�+��ZM�c��OX��?���/�S���Tu��W�xOD�Y�a��������Xw2����W4�?�;-��B��k���^�:]i�2������m����D�n�6��uވu��sZcO|,��7k����VԴ�5��)-�a�[Q#qb�P)����5��X��s��zj^�`7~d&�Ta���E�p�4�>R�WV)��B���nw����n?��'t�	�v�v��������k
-�>����j
-�mRc�K��%�	+d��߳:ѕ�.�ه�"���C�]���E���"����E:R��x�^Ç
-��C:=4�ֿ�m�
-9D���ߔ��������:\��di�M���C�3��E��=�4�V$�p�kv���Xڤ�֟O��g��E��p���������O׃x�B�3�R>��s4���Q*ת9�����jޏ[�y�᪵�σ�H��Z6�R�-�lXaO�W�cWI�MA�LW���������a]��
-�݆�P^�7���^7OTw�"��!:�:�-D�X^u��vk���q:��l���(P� *�u}��Պ��;ڕ�S�=.~?vh^�WQy��T
-H���:"�(�Q���� �+[����a
-R��0U:ؼO�}o���|�C��
-�P��y"
-���_�;#fE{j�nC�j�%R#b
-��*U%UU�GU�*�<6�>�L?(N�O��Wԣl ���0�}y�4cي�
-%<�t%[�I2�ϕTN>�OVo���K<�������D����A����yR8:S�L
-'����j3S�������d�ݴ`�\Lzs�;?nȼ��g�aXW��h��܂g��������M�$s�����.	y�W�4����O`(��}vj8�D�L�τ.��g����},
-��N����[C��")�8��U0n��к2�� z����+z@���� �2�9 z����e@ �����ʀfh�h.�6���i{8)�,_8#׈Ȭ�ȥ2��)�hL�q�ۙyo�gz�S�zɞi�g2_d�t��}��9��}��DVQܡ
-\TpW\@�%2�
-�UDED6���?7"2���{޼ϟTƽ��s�=��s�����n�{�Jн Z��@���Ы���Z����rs"m�
-�՗���,�������Je�v���<$^����K�7Ty��ʕ���Y�z�SE\$/��C�K!����2��c,�茖��h�KjϏq�:�o�����ա�<��!AS��z�?�[3}U(F�ZaU����4a6���wE��!�ܓ��H���jɤ\����0���ZX>]_p�w�
-���Q�p���
-�4�@j����grg�g�T�$;�����;5�-)ܩ��H~z��u'��'����gic��i�i�$\�W�jC��4$*c#�Ϡ__N�?[���:�:��"j�ɩ�T��X�>�~�s�E<�U��׺U�ϒ~����IY��x�$(��,��7m���=�ԥOK��'rSS0rX��^�U{ϥ��6$^���gUz��{�TƵ�e�e|�0���%�oz��OH�NK� ���� ��Kّ�o���f/�D�����#I )�b�z�7=%�q��BT	6� ��T#TYcԄ ˋ'*%˥d%ѠkBX����;�74zN㳰6�o�P*�He�&��7{cJ�q&��ƯU��qҍ�7��^��oJy�M��)O(뙕�.�ܜ�/�ܒ�+�[S�♝�x�m)���9"�T`*���x�Vk�_�~C�=��K�-����& ��	g^��-��y�>���l��O���)��
-�Xfڱ
-fnM������5��S-ߗ�J�@��SƖT��ڠU�Kʫ]�L�?�
-�S-p��~�-�P~����Y[�m@OV�8K���IV��g�(~J�6˓b��I-?
-�,��6�(���FiTө\5��>��4*,��#�銗*�r�Y|�T3�@U �� T�Mn�� �� ����HD�6��;j=Gݢ>�Ȉ݇�� ���2°�ϙ�q6۝}
-6%��h��͕W��*-�Tse��*�H04J,ч��$��JD
-�.�"�����R��)}UP_��I�S����R�����V �͏�k�����sx�
- <~�S�r�}(��x�
-k��+͕�Za��Y�\Y�^�2�7W^�
-��k͕u��Uʰ����_�lEa��#w�&u�zU�������~��k��[Zfms�-��^˼�\Y�6j���+��-����A+l�2��+���&-����	�{]��Ѕ��}�\{��3�v��3��Je1(���z�!�@~������!�@����CJ���s3���UA�}(U|(E�����ŵ��������ڵ�g�*v�����
-
-q�Z�i�x*�[�f��h��4��N�}��A+����.L���rky[~&5W�𡇧�pZ
-S4���S=ݤ-T�ӣ�����k�-���/��od�]%u���Wō0^�`<�x�Y63w%���*Ȫ���Dq���*x"�!BuȤR��@C19��qҍ�ϥ���I� �������I�U���[53�'Fi���+7��{>%]�zI	ʸ5��⣉�r�8�D���MB�_՚8�����:�Cu�aA�MX��G�Z���`�s���êfZ���q�nrF��H����)xc3�ƍ��9vk�͕�Z�]-����V�2ۚ+Za������S+l�2;�+۴�.-����K+��2�+{�B��h��k�w�̮��;Za��9�\٫�k��͕�Za��y���U+��2��+;��{Z�Ps�=���X��S���_�V9���(E
-�W�A�.]䫛����qCk�go8�<2+�C#�}�e�vg�ee;�*0j<�p-�����Aa�k���]�윟v[v�nw�x#=vpS�i�(��a�x����c`l�l��n�F�.\Oخ���sz�;�H�e��9HO��{�'��'Cu����:ҽ�t��aߩ�ng��
-�:4�
-�s>r � b�q� ��р1�9@�I8�F��Ɣ���D���~"_Fe���`�p��":I�w����PD��%��e�=���+[(���&����ƚ?�
-ˏ!H�	؏E�>�n�X^��[P]��ɽp�����ux�	v�K'B�K)��f�on�+�O��zP�Q�&S}��ϐ��$�~<���>J��a���4\#qg?���]�=��C>�uO8��c��ϣ��f�C��Bݟ�<�c!��*>⣟�C��~��
-����Yc�Ã1�Mk���P
-��Ԍh�<	4l $��[<v���at��zѰa��N�8�?n����}\�$�tx�����Y�7�:GB�����$���'�ѸS
-l6��d���+��ֵL|�HB�_U\2+~Ρ��,�h���22Sfc�3���(B��T��	��|�72�;m�_���Ꙅ�M��깄>[��O��`:����O��_�����D����r�z�}?��_"��S�?�,�1F�����x����d�#�x������ٲz��N��ޅ� �w�ܓ a]�"?$0!�)�a�8����t�{��H ;@��j�Q((x�����}k�@�P��=Q�y�;�O��@� ��l��U��%����!��8�S��Zp���� �&���M��W#^�o
-W�zTt8v���ܝ�׫�7ͤ��:]�m螣
-;��e�x>!c��I`�W��@�[�/-��H��e�	YR�~\���>�ެ�P߬�[����r���>����o��o�� �^�>�X�ڗ����*O!��~d��I~3�>��T�A�u�a�-s�T9�J<:�H/� ��L��L����C�]DzI�_��ձR&eDZ�iS�H:�E`Y�Dj85�D�\�U>�
-��3��AT��F�<��f�E�b[��{R��r�:���� ��ɀc�U�e	�L�y#�[ ���j�j��$CH=��JO�H�m��R5���^b뙑�]G��H�[��ύ��_O~��z�#�o����
-�L!S&R�D���Ms�[@�.W�<��oɸJRx���%��Lw�f����g��⣴�]굮6o.����fZ4lUw�X�5Rk炝��Zb��H���`�5#�nd�=N��F��sz�mj����ׁx�;�Ļ���@l�N�m�z�~+���sK]������>r�m���oe˙�-sa��`���cgN��aH���~J��r���ou!?� ߊ�~�í#1Y?3Y�\����35�nW�2�QƧN�#�����*Sa&u�2s�q�)��q�����~���c��4W�#C��p��?����Q��A�C��d=���n7_�W\o�ԑԀ������[��8Tv˂�?�g};�wB�^=�S���j�-Ǘ*a���r&�=�$Ri�<�ӯG\'�7��9��/��t˘�:8/+EƔ�Ɣ���;d�Ͽ'gߓ=��7��I�\����t3׍-��7ڃ�;�4���Hy}�oȫJ��.�LïۄR}l�G��;�����H����ID�{S��m4M�9{q��z�k�E���y��&q��$~.4���t�%F,A@7M�Kۀ�d����Lt�᯿#6�FP���U�/O
-��4�llL)>��SJR�}���R�Ҩ1��Ɣ��5P]B��ïV>��i.j�ɖ��`-���{e�9���}_�Y*��2v�8 -���µ�2��C� /� �/��@m��?t��Е���h��U�(W{��
-�G�>va�7��N���r�d$4���{����W��4��I����qq]�:yB��HSN(�2Z�1�Q�ޔ�� e�v�]36�#��ʈ��
-�����޳F.)�RC�K]�1��y��v.�l��N��MC��G��}$K�6
-?*ٲupPd�#�󾀙�/ ���#��)*ql����4ţ�
-�\<��Q�2�ߊ�γ��!�J#R����p��l���r��)��+����r�s���Q����
-��B�5 Ϲ�<�Zjɍa$��_��~&�ʤ
-1]�|����;H�x6;��;�7�o�~OR|��tV���������ΝX:ǈ�A����	ha�5'�������y�9�H���nN�F��X�2������H�� �Q�Ɣ��؏�ht��6����^���!�2�%zcx�i1+��0�~������"��im2��r>��ꤑl� ��RɔW�-g�Mf��U�UR����z>?/j���|T���H0�i�iF��C4<ˁ{�z	ꂁ�-��>���.�)$ҹ0��)�o��RK��~О�;����Щ��]Hy/EK7s%���g��J1�_&M����2�c�z��h�k�!v>kN�E\����#�f��;x��p/b���X#7�LA���q3�f\l3����ԝ�4�3EL�Ŭ4��#�<�ƅ�q�`���߶�tШ5.�CK�a~���O�a.pu�IC�2�0��`.l���sQ#Lb$���mtV�ȝ57^�G��v�o�uA]�7�ᷪ��*��g��o���R������o0��q�Z�C��R������A�.�a٠��XR�F-<�Ƚ��<�L(��.#vW�$;�
-�lx6�	?�:��il�A|dܓ�� [`]��p�mM�!�-cX���4:k�'��'ĭ�8B ;m��m��!��p��aյ�jC�I��p�yh��mh�	�.J�G�=%�
-�
-��%<(�̚\���/K�1�И�<�����1��~\f����q���%�����.�ҋ+�G��[�x�
-��P��_���Wk�BsH8����ߟ�z�ӂ�b��� [Q�\]e�9̰�S���s�+�� LI=��(T	��	�_�z���$�/YqX�����^<��^d-�zZ��ܤF�!���G��R �a����l�c�X���?I=�Ix/�9�Ӭ؉�[E0�(Zq¿8Bw�4W)vl�|��42r�?C&�؂�CZ ���[��Z0y�L�_4���iFw��:-~R����?DG��!q�����iH�/A��TGnY�08�ӊ��
-	�ё'V�� �#<���-�
- f`\�#1'4��2��ز&�GN
-��<m���p�U���ɹ�}���,Hm4��y�C�[�I1��L�k�ǖ�Üx�|^qJ����a\�f�)���3p����)��V��8�S(�� �f��
-����a����
-�8���oR&�v_�)��I��|��nI!��L���D�T���M�H�vD�.,�j���(OS�e&X����w�����V�T�o�H%���PG�s�9OO�Ԋ~�?g����s���[�Y݂���z��e	�kJ~�����,�~�ś�#�e��ә��Lg ��Pq6�t>�����9 ���6�����+����@�x{�9��<�Ų#���(�[˳�I�)���m�Wc��P�	���bVp��tik��K[�]�j�e�֥��ң��ңC�� [ѥ�����-ӵ�G{~^jӏɦ�V<�2�hҸ%�o	7D��z��X�Gǔ�ǔ�1|Z܎��N����m���W���uRbZ!��pD��/��V������O%kS�	�mCÖ���
-�P��~�5����R&���+�P��F���PO��8B��M�����\^�x���ۆ�,~��W��r���m[1�Zsm�4Q�4���ݥQ�$���=��3=J�ƽ.�<<�y�cK����rX���J4M�U��d�|gq��i8�h��`1k�M��G��}ߨ�H|�>�ic�L�Y_��^;�7��ܴ��#_� hb5�aQ�Q�2�5�-^���C�
-X�p��A���rg�(�
-��:<\V�gHA�0��|�:�Խ8��n7v3�5)b�T��Z�)�܇S}�����l>���;c�/J4]�Ŗ%�lH�7�67V����ట�GI�:`(E���!�k�Dݣ$
-o*�Q6J��Q��6�5J�CG�{�X�QQ�b(C|�Q��Ґ���o�(�g����(ɍ-%�(�Q�$���F�V9d�]��I��n�[��u3ج�Y��F3�mb0Y`�
-ߡ��M"~
-�g��i��Q|O��-~��\s�&lr��L��T��d�䏼���8�#rU�GR�dJ�	�կ�ø�ݺ��<�֪���F��� �G��[Z�Q�?d�søq����kX��K��L˨���0�!nWU�X�u�*l�Xws�
-1\��wW���V�]n?����d��&�#©A���^����e�M�F�ٴ�Q+��;\����$�i��@������U�=�J����kL�ߕ4�1i>�t�)���o��C[[�C9ʺ���m�����5m�_�{�"pm[%���
-����/��0���rR���S?=�e��f�m׽�'ZRa�d��u.J?ȶY@�{д���˭�Tq7�S�o��p�R��w�]"��`[7�	�'Z�n�G��(I��єᏈ�-�3�g�!���	#`'�'b����l��丵Yb�㗱}6E�^�Ul�W�����Bf��=80�v���o�?�i�
-x���K���c�����r�����F�x"<̢�a��T�0�7>���T�I��pt��s5���0���[)|���ҙג�ex�̭|�������Xa;V�+�M
-鵛��{R~�ԽB�Tޓ��������CJ�=���=��G6��?��6żVx]L�_�௾����9��䴾7�<��_ ��Ƭ��^Z@iN	ȷ9�?�·�ܔ4|�+%
-J~+Z��ުH���.;��S��i���4{��&��h|�3�����V^��D��c����tyfZծG�J�G����b����;�|.Lڠ7���
-��
-�����+h29�$�K}pPas���ܴ�M��q�pP�V*�m�C�P�j'��ثS��(�ٰ���c���L�9� �q� ��b; ^t ��v@��@��J�g�5%[S<�I��lF�¢�$�}��8��coRj�;���8���do1�	�x#|
-�§�+\xv�~5V^��%��bf�Q���4ysw�=�
-M�����AwJ�6�鋺�m�
-�̖de=��zX�����nk��(8�(|@�� �aSk��ܽi�5.�� �j � ׆��}~P��6q���>8?ٙ�į`��1���}i}����U��wZ�1.Q���?7?�?��i���n��b�G�QYu<A�e�[
-�>~+�/�����:4^X���ɅD�LZ��wy���R�%SZH��Ғ������Ûa8[9$�<͔�ަ�_6R
-���JN�j�+̭B7���vļUD��jD��i%v�ĎFJ�B�L�.�D��i�:f�(��ݬH���h�����^������dK�+mGW�z�T�MO��8�/���q�"X���?c�
-�=o��Z a��P�|O,I<��L�}��9E�-��Qr�PT�Bnx��Rυ5�Y�.nJ����3t��]gqq�p�$�!%��R˽�H���/��F�f*'��)s�y\�~^�K;a�G6�	�Qխ1�,�3�[I��f�KH��jv��q#��� ���E��EE3/*��x=��N�8�|D��8�Ŭ&Iw�i?���$[�
-�{������b�ʁ�и�P����8��4�Pm��G�`���$�<�!��օ���
-����'ld�1�[5[`�b�Rr��3iI d;A�R
-ҿP�7�����ɒ,�()�1��j?��X�'/iЋ�thه�������HR�;�"�[)ׄ��z�pn 6��<�uu$M��M\�s�(E��E~��s~��P��rawr��ܞ4A�[��࠽�C�Xe5���^�J��Ƽ��7��U6���4s5y�؜i��o��H>R���]Iv�"i��w
-�m���]���3˥��K�[H���Y�	�%)WB�n�i�Ӳ�����Z����d��S�C�q~N���J��(��܌��vyq�^�g)�=�H����Ⰿ��J�I4��N�[x�&��8�ٝ�V����=I�Y'��.����ieT��h���ԗ�p���X�Ek���;��� ubh^H��Ѕ���x�u�pׄ^��t�p(�,�w�@A���/��h�ۀO:>�Q�˽�z�{7y1�L�����WhI����Ѵ'${0�<���J�R��X��Z=��j���ßJ��X�A��]/K�`��
-�6&bk"�f)��꒹��BZ0��0 z���4��UlѮ�F� 덚�^Z�H�V�&9���������ߌah�#��z��p:�!@��D��8�������z*_���|��of�H����(� ,����p�B�흗 �Q0lբ0�+�.�C"�@�-0�Z��3$�,��I\F�I��\+�,�C�/��ǁ^#��u[���D� �f*oR�i]���/S\�T+
-w��R��y?��Y��m�� �j4�lI����R��o�����./�N���h-�졯��r��LPs٭��?0��g(�m�;#T��U˿b9�m9ŋ�wx�[���G��}d�E��j��~Hɾ�x{��+� ��S&2߼�d_Q<�����s*���U$O{Ex�|�E[x2�)=��su�ojbț��-aԗ6�}i��$-��HC(�3�]��U6]�zXO_�e5���� �2�\M|����5H[*�V>�1!���({��/$�_��s23���27sD���� �$j�����&�S��V:�ݰ��*���1ؕ;ɍ���1����Rv�a��0䢸����Sr�)��]$[���&u��突zԸ��.P��6�kD��E�]a�rb�J�՟B��4��X�L��F�z�����A��kI��s4���焒G�ź�H)��0�
-u�d�>j�����Yg9M"����*O�UcIU�l���\��M�b���0�f�j�7��WZn�#�B�^�0��YO������dQ��'z������Ł/a���,��G1?��h)�?a����e&߄�&ҝӞ��$�`��������I��T7�y�Ҋ�7 �(M�'���<��������¬ciK���k���ͬ}��ZZ��Uj�2@kК�	�`��	h�ڀ6��$x������J�+�83�>&�wy'����j��̔�J�Za���b_���s��lbR��1-��ꃩ�0�c��$��ڕ�͞+X��)k�&Z�VC�N{��\+B4�6��n4�Y͝�[��RX�� �o� +�
-���4�*֤Rs�)������L(!�P�4���|��E ����u�<�8Ŝ4��S������}�DT=bq2u��:D�Hdh�<S�3P_R��"�>춿�^b;J�M�W�i��{�"~Jɭ����4<�0�4���wՇqv���;f16m!�q���ư�}5��\�C�~S��\��~���R�k�ն��l(���k٫����X�E��33��P�so��~T�\y��K�§&��h>�*o�*oP(lf_NK���@<���۽���;�$^dY"f�.�
-����^���Y��P�3}y����>���v���e��i�G=����WK�W��嫢HeZ-WU������7��Gy�k'��� ����J�k+_�h���N�Q�mt~ƀ`Sp�M�G)�QŚ��T���~�_�G��n��fUS�(�c����s����|IU���n���Ds]�[�\P���t5�*-�V��fÉ��p\h6���� �]�$�9�.�t`;j�G->F���Ӌx%�
-ag'y��$$4,ĺsFZ4�{q��t?�WM������W��	^F:3��n%�gv=���NC�%saj��Nz(c�Y�����Mi�_O!^(R��i\�����������H�u$��-0��dī��+��=���)ޚ�VR�5����e���;�'�9�]7`m� �*6�;�s��k�.����@ɯ�B��V�
-"X(�'򥖹]�|��k����q�����M�|�>�23��gZᘖ�Q��
-G��rD+|�ux+_i��Z��rT+��:��Z�s�#P��-���J�O�jF�5?Y힬z*7��>�JO�O-L��4�p/~�U�Ԯ�,�p�z��r��� '�}1}�j]���ŧ&��.>�e{����դ�T��yjv�J�%�ùAk�#A?��ҧ�f~|���2�=���{�o�PuJ�`C��=�����0�؂���N"�7��Fk�)�d�u��;08(�e�N�Fl��T�Ǌ�~���f�G�X���o�{Ƌ���� �kբ4}�r��ش+�,r�Ûi��1���	#��LT0!*x�~�^�jV	5��@��{�JދJ�d��Q13�������*��M�U���w�v�M�>&J�)Ӥ,Ud�I��N��#�-��#4�`z֪�N�BAn�B~������}��-*��&���1��V6�^�V.�:.L�F��y�*�̹�$<�ui���_©��Uw�1��UN'v=b�h$80?ܩ��;U	�^,*
-�[��\Xة�ǵ"�FaG�?=��`�?�zԪ��@:�3 j����aPC��4᠂�,���5|P܊{E(�Oj�)�m����I�IÝS��-�H'�&���y7]|w(�uij̐������q����C�v��;���Lw�ە.��q���ջ�{����I��M{�M�9�[��o�$sSK~L�ul�u����Z�L�#eN{��s;��� ,�h#��;X�]f�k���C�Z��Y^�C�a����Fp��$����r���@��,
-d�J��"�#13���s��D_��.s�<�)����#qr=&ssq;8ໂ,I�'$���ܯ��^������>L{�^�G��	�r@��'V���H�fR�T�f�egR�m�c�7�3s[�Y�8���~����P�J��R��F���N���~�ࣖ}f��Bo��;(�ࢬ�I�Ʀ:�D�7���_�4VF_ �
-9ߞe��
-O_����{T���Z1��G|T��g �?;E�3W�P��OwHы��:��\0A=�(xD�@j57_�h�����V���O)�S��"�y�S�y\���ơ�ק��?vD��>f��c�}��8��(��agʝ�
- �0TQ��/ʳ3�_&<��q���Xtd�=UҔlO�luԞ*9`O���J�S%��(��}\�է�N�w5vŉ���t^��������pn8}�w7��%!��3ڰ
-,���=\�L���_��V�c\ߎؾEE���������P��G">I
->��?��K"pB��}�oi�9����
-��؆�}�����/�f�&��T�|,�;N?���6G��e��yP��î��'��x�����E>� ��e^W;+���Y��,�����1��d�گI&���vݮB��.���/�8.��@X�����jV�6�
-+��t��I��*��(��>q'�A�����"�y��ϛ4P�Axv��qu����.�dy���RLvgT*�U�8����!�|$=�?�#�[��U6����
-�~Fe J(o�P��'�X/���k�Vy��Zս�*/���D��j�
-o�[�>\x�b�UG���r+�t*�\�v���*�e�쏻�?�d?��/Dl���)�q���Ļ�xɡ»��~�?�|�+��=���Ӫٙ{���+<D�'��	���L�I�0`a�m�ʻ�h������<N��V�dw��t��W9U݊���^DU�JM۪�ƃCF� �.��Z�?��5��[��B�s����Z>���v�}B���O����K$$��%)�C�rB�4˩v>@�8�\����nv�)��)��䱞0$FJ��9��ITF����W��Ա�����0�~��>%=ꐚ;�z������n��|���{�]��T��#�e���L�����*_�ߥ�
-R���$/�o���u�z��B�f�"h��B�.��M�"2��
-�Eک{��K�r��]ӄ(��٫f>�<C����/1������ر��f? �dTp��]�zz�X��� b]��8��Ś�!�+-(h?�5�-2�-���W�m�*��Y�	tx�LQj����(�!9�����ɘ��`G���x\+à���XE|�!O�2˜ǓHZų+Tar�J���2}�)A������1Xy�H��	2q�u{��X�\�BB`�W�[���L�:�2��+��sl�ͺS�SD�ik�9����ҕ�Ԃ�ߟ�+�Z���|
-�C��:�:�	 �"[a�����_y�[����oM@Q$�9�\�.�I�=��5��iOD�H{�Z�i�/i������y��봧I�L{���Z�E=��Y���O���z��<׷zB�gR�G�<k"�p8r؏������#j����E<��|��N֕�18�����N�b`�AM|0�;��a���0����ߊs����x�2������<���1F���Hf���� �&�z�T
-R��Wm�#�f�R����E|�.B���D���졺L��$��5j��?%/���!x4�|.���S2�O�R�i��Y�=7�4�-�x����4<Y�ۊ�aa�bP����w3��B�O#o[��j�,�
-�6�cK*���ʪ��F���Ah	k#�P8r�O���@W)��7��zO��/�ܗ��Ա.R��j�Z�O�R�ik��
-�dEk
-.���������)�d�WT��}�%�.���7��41��Ƈ��ڟ�<�VOf�*v�a'#,�D�o%�@giwx���|)S��B��CX����/�HPVֳR����%�"_,CdyQ�
-�H�:�!IA��z�����I���-��T{�=����gRZ���u�`�m}�`և�܆��&�C�e��OWqrka/EWH֝R�2@[�v���/I�b�+c'e$V����b<3_ĳ+Bl��wW[��vj���:fEP��>��7�p�C�5xzT�Q�X<�2�Ň��.�5;�c�q�z��>���1Է��m�C}`A�
-�
-�t��+WRd�!2��	sQv"<X�_���SלzRX�#����&C�w{���l�2�����؝�w�оEi4t��]�u��+��	n��Ɵ������`��h�Òd���岞^�r��*k,l��M��>�2�l�� $(�6�\X)w�XV�
����UL��_MvTr��^Ğ�#�>φ4��-E��ٽ�Ǳ��
-��G�#������>�a���פ��r_���o����虑:�X���( �}�H����8��t�D�t�=�z��>��ib�Q�,����#����ߵG6��u�t#��kK�6��6��Q��b����
-r��Q��U����S�);��w"R�.�~�$=�.I��wH�s���5���7{R�x��GQ��4�^�B���A��9.���}�*�лh�NK�.,�iy,l������g'�m��׮^�ë`��Ӻ���U���������7_R�W���9�ʔuL���bW_�bD�bD_OQX�˯����ujnv��糪��v�ٗSqH��ڙ;���q��ʫR�
-��y��v�:����pO���L��O�����p'��@�������k%�s��.o1�H��ô�����R����޻�IUey��D�xd�G�� �*լL
-�ֶ����n�z�DQt�ʚۭ��܈9Yw����[�3}��'M�oŷf�4�
-���E=��ݚ_����Ep`NLRf�%4�
-��C�A�����RE3}��C��04=��O�H��2Z�Š�A�z�Ѥk�na��Z)s#l���2��(�m�/c9�ԭZ������U������eBW��47��Y#u-T�)_+y
-$�7�m�d\��@ ��1yKL��0�D)�n
-���-�2����+�>�õv�/ys�obj&W�=9S��4�,��1�ķ!��֘l�i_,u��Du[L����5�t��az(���KB��N�X�ΘDͯ-y�9Kƛ�u��Nm�w9�t�C?&���&�R�`�'P}��O���G���pF�jü �L�l�JP��z�zX=۹O-Cκ�e��B>'��g��
-x�~wL
-�I��$�ROL�Ťޘl���`�jYL�3�{��H�}1��?&���b�̱��NXz���$=c�W����(���Ld�L<
--;��P�tS��;X��4{`����.�llz��]x�f��Xr��e����T:BS�W��o��)}n���r/��%�>���Jz��'����Ml~�M8k��?�3&g�2�k���!�RZ7����WR�8m����)~~�g��B���և�(Ħ櫅�|n�D�>b\_��c[�
-��Ӛ�>���ϲٰ�B�rb��V�RWڻ���X!�|Թ�&�-�ti>t*Ŭ�{�I8�"�n�pg˭���S���"�'2*ԁfy8n
-��,�
-Z/R;	�7?�Yg��]�S
-l慉z���q�	�KkeIV��xq�ps��C�;B���v�_aT�L���<([x��/k>b̯�>��@�)��֓.}����b�ė_��r�U���O��&���m����CL����l���x����d38Õua�DӠ.����2�p68Y�K!k����i��7�
-pp�
-T�y��v�q�xwx��N�Op�Ѐמ�k_=#�hU�wم�]��r1s
-��nݧ�����q���Ѐ�K�1mCԳE��_�Ҷ!VF�`��k!�����������ݤ��7��u�}�g��u�S�i7�R�*���p�Z�Iut���d(<�� 4m��>�m2�;�d3G���-𾪊�_�� [���~��q���s�ƹ��`uXroL���n���`�󦶫lX�UJnWqv�Ј��;)}�n��#M�#�?�r�F�~c���P�%��m���p�T?��-]j�A�3b��;�RE�E�^������A��<P.�R���x9efCI����	@]*�>T�1�K�(eC���T���~M�􍲌(����{FրŎ�h �;��ƍ�7��~45�\m��4�p��[
-��ճz�
-�&��E��@n_���ǟ~�)�:�#�I���+ƺ�	�~B|9#�T!��R��<�?�3���C��Q�"(6�b#(6�K}	e~��/�/���Bߠ���0|^��^���u�E\���[ɔ:̃�*"��z�A�#DrF�:E�a���hE����W�:r�YCY�ꇕ��׫^9�8�
-udC D�sh��ߞ�j	du�]�����4�������*�Or��P�Y�7�X�M���V)���j�M��L_� P��% 
-�t$t'v�>�~N�p�~h%�mr�
-6H�R�iܳ��G����r���|�� x]��&�k��
-��!4N�и����t�q:��1��<��Wh<�B�X��Z����2���r�A��9<�I��$�gI�7��1W�ғ%5�d�dp�,��%�D�$�mn��7�u�!���V��a�J��zuX�W�c�����B�ٺ6*�%�1M�#b���)���5'�w�:
-Wz;Z)�
-pA���Ƥ�
-0Kc��g�D����q������ج��o!�[r׷��5�Z�NZ�J]�+C�D�)�+Tj�2'e�=%Kk�b?\e��S)R�pz���T���K���C۫�z���o�K5�34�3<�prg�n�����Br���!wE��]/�A�O�&'�3ڷd����+����,�l@%�ݴ}�W�M�s3����I�OG�vL4}TI���y�a�����a�<�<�t2mJ��R{HeF6��ޏ�0Z������DZ��̆��.�+`���� �Ɇ��zʃ�Q/��� �d�y����|^���'t�0Yĵ�]u�N8��OԨ�l���^Q�lwYfh�	[]�(��E����a�
-SԱ������X�p�� �
-6
-��9nB�k�[��(�VKKK�s��ÈWt��H�h�5��\r���Eq���+�ʫ��Z�\$�����yi������~�٣/�]��'(�S�o��	���m���ۍnP�+�n�_��f�	y���
-0c|Y3a�{x.xGu~�
-\G.���G���mLp�@��hs�MS�HM�f��<�xA��F���
-Gg��M�_��Ք*���W�$��0�w������*�
-���#z���^N���Vo۫7�+�xW�q���2E��<�KqK_t�8��I��,!׳\Ƚx�:V^+ۢs�ّ�����PЀ)G=���J��u�����z��z�S#"N�ELbI��-�M�i�NV9�I}�È�4~G4ޑ'tjX�[>�'���l}�-�7�1_��)
-���\�\��
-��u�����m���m��u8��_��o�L�+LK��RXcSz g����۸5��7���qt-�u��q���lĵ�qI���#�ߘ!O��o�*O�h�N��h@S/�[|�>�*��"~>�K���oYkt�W��j��ت*�v5,a�aԚuQ���9I����Bjfw�����y*U(��w�{�8���(�eP���^��}�v�
-����r���Zx�
-�Q=J1.���a�u����%��A_�8���t��q��a���p�vb�I�����������ӧ�b�8�{���I��$�����K�lu-���~�|X�
-�.�F�qp�F;���#b���g�2�*0���
-<ː�|T��ī�'�����
-|r�
-(�*�ayX��V���P!�mٟ���x�(���(�i�}�*�R�T��OݤY^�{���8i6']D�����ZOf}��V"(#���~>�����Ǡ���(��<�F��o8|�5L�aAMh�����W�P���p�I���,����g��,Y&�u4���xB10�8��p	l�$����q螉�cnL Vtikʊā��0��b~�	&,���R��yf6���Yt׍ƈ'J��Di.��I�R@<QJ����:{� sw�-�G�7(3wų�pЁ��g���$�Q��f�}p4!�L ,��x
-���{0�z(\l�5���YZ���L��_��0�\Gh���֗��,_2��ߤ��R��-6���5�/��G��V.���}?o-�Aկ�!_��3�mX���0Y"�/�h����x���D%�3��Z�^/��R��.6�$ ���B�K��/��S�ŶP+��b����¼�!��!�`̗�k�~��г�< _Y�oc
-D#M曏��K������
-)�cF��y��Z��SF������~ʶ��m��mZܽ
-��
-�7Hܑ��0O
-��S�\P�׈
-f���RV7���_�Q�_>fL:fH]ǌN�h�]�ؖ(	�=썡ܻ��#q����\|6�pݬ�c��<��}��9�U�g!�A�
-5�:E�ևK��S��h���sn�8��`�W�7�W�W��0�I����ω��S�S#&�*��|����ͳM�����I
-�>��b��R���֑��q��r;�N���dY0z�����h
-�̀�O��ܬQ���Z<Z�rk�
-�g�|�2�8�2N���z����'�ʸ����o�����F>�[��5q]�ʍ�\���� G����k��\s-*&?�Jϳ���y��5✧����"�a�zgc?�6�/���0�l��\7_���=�Q��P	��
-�rB~ӆ�*���8����̿����퇠�m@:�[�X��l%�A'4Ra�7���z�l�����/?[~�l���e�\��\�N�����Vxc~c�ң��4�G�WVEp~��[u��ۭ�xO�`�k@��C�!x
-`츳 �����Ҏ�R�4�H�Ls�@S��=�!��-^��	�[��{,��� Vyig� I�?��֥@ecн����o�z�t]���t]${8��B_��`V������3A�̠�y��vREׄ[�k����x�_`}q��~(ܥ�8~)�R�7Ԇ��{����3��P�@!��滾S���fZ�/M-���r�R��`j�^�G�@�;��su�~�G��%}��
-�ۄIHy]�6"��Z�n�lk=ۗ>������=���m���c�������s���ɞ�s;�3�E�~"q�� ��:�0�?������p��D���4�k��8�E.h�{���"j��=��g�:�]�s
-G�L+v|��Up޶�!�'����mO����6�%*0��F��2�{�"�߃i92���B�OI�I-���"�}���C�$�Ln�e���1n��Q�q�`���m� jՀ�.��I����P�߆:
-mgLԃx��]͔�ˏl�c2n>DG���q�e�)�.(�l�fdo�ܓ_��v�_��7�A�w���U��n��t�����G#��D��e&����0
-�nş^������T͵4�(�Oii�����A����&�cg�jbM�#�����am��,��m���o�>˷\�L��Kxx ���XTm�.|�yd?�t%��%�!y�o�L\%˙�_H!��)��[�?�'N&�'���H,lL�lN�jN<�|��K�eg��^x5.������$3�E�p�Ys�0o4����EB�ok�-�(��Lf���w�啰�,���=�����{8'PG�d�Z`ӥ� ��~�eBOOpo\Ħ_��s�:�	������xn_�~U�'���BH�	����{ݦ�G������s�6*}�8�Q�>�[�~N5��|�T�q�TAz���- ]\��-B��y�H�
-Ϙ�گO�����Nڂf�2��p]8���@*;)+ue'�<�[���3���y���`6<�U`ڻ_g�A�����M:}����q��K�8T�{H���:�wҥ,|,���t	���z��ix�\���q�D��{�	%z�i��/�Z���ʰ�h�C���RA�C�{��K:�t�a��D%�Jn�^hl��8q��T��Oe|8���Kw�k�tѨ��f��q��A8�4�� /p}1Nj砃S4q��#�[���z�v
"��V�
-@W#}������y�$��E}�
-*̝Σ=D|�
-�֚�Ƶ����T"�����a��f�;���|r��4�]ʿ��/�� ���%k1'R�з�p�1ClL�*@.<ⵏ��/Q��;f̠ٗ���
-y��z,���;sŸ�2���#��#:��lߞ�����p�Z�OT-uĢp�=+�b�T�L�A3�G(M*	ـ�7@�L�Qx��| ��)��t�Pj`m��q� 
-T�t��
-t��[�p\���Q�F��W��� ?�$\lc��vnS�}Bo�g4�JqZ&\F``vZ�Rd�ޜ{>n?��W�:H'_������>=��N7F���}���d-���t�~����8d�q�>�f�)��:Ρ��~�Y4}>:3���eF'0s������X��������_̧i%z��uث!I~k�/(�?��m�o�q_A8ty�	�+�v�W�@�+U`�����
-�2C���w�&�a]���]�ы]��r�J:d�R'���`�����2p)��W�"��~�Hjo�0�����|5�F�L˧$��y�o�|�b�3����+O�H�c���O�3F�Kj����cr3�PF6�ޯ�W���5�ĝR�}�DF)�>z,�}�H0�9��J�\�=�̓zP�࢘���"M
-+�;h{u6�����N�9
-�p�~����&���b���#w��_楸�'
-�� �8˚��Dw�XV�
-��^(�PU�;U�ۜ��G�X�(�U��� �^����vP����~�\5X���%����)��$*����N��AOko5�ݠZf��q�
-�,�� �<���d�7�'���`����:~2\p���dx�
-�q�7C�"~a7�c!TE.�
-�&����C%��܃�[
-����@;�� ����I��>���j�����E�/�V�5d2�����1�(�t9	j�%�I=kb���
-������X�1�6+�[3�ڔ�c���Q%>7�r]�Pt2�]b凌�Þ�;��1һ���F3�<f�����OY�Mc��Ƥ���Ӗ��b���҆}�}�e5P�~�2�X����Ǣ����0s��i� v���^��iO�4M�����"ޚ��/��~e�QR�G
-i��,�t����m�	#��m1
-vtF~y
-}��7�M���D���ob��s3�NL���T�f��ԢǑs��k�
-�,�_R�n���ࢁ'�1��hj��Ǜd����*���챽i�������ǌ��o����y��:W�.(��WȽoA�z�Eӥ�+)����h;�h�������h�lb5 �X�����B~OCz5�6Rg��O������zY�@�y�'�	 ��A�ú�����E����K�����a	�ob쾠�fU|&,�D�[8+���A�z�hq�p�9�ۼB	r���A<�;x�� ���A�*4|�&��5`D�'3(�
-��/�YV�铆"�����b|c�O7�xT�<͕|�)�Bv�n�dWuL�3�����a���zG������~?���P����]�,g�5̾Ǘ�i�gV�M�s�	?�&S�=��Hn6�I�rW�@���ez}��±Ʌc��{�2E3���}w0s7����E?K���A,{��S���r�! �jx\ɝ��r\��c���Ib���ݰZԊ�\���:^����+�Bn�Xh��}�T�1ݸh`��ɫe���=�6P��	EU�*>s
-\�O <@ :�kɟ�Ѭn�hZ�m��ײ�T�>�k��`U\���I@!l�)��
-~@�\H����sF�(<;�c�O:���6�ƍc�M%K!:+�П�t��`K�C0ק`��v�Z�g�
-u�L��ߚ��W�b�t
-:+���.�O��h_�C��1��"4E�>!���[�.VA�T�c^�S<] >*��,�g	�G#�-�1���ݐ~��*��	6��#�{)n��L��+�� �(�d����#�T���`����VL�T
-�.��̴'Z%���:�X��0�*����tysϪh�iBg�V�@�t<��ex佔�kOZ>6P o���$	�vʅdV\���UE�����m!S�������+LB
-k��W2h�g�Lu	XT�5��4�W�2�z�c=_b|�����ė��`��E�wL/�cBO9��zUz���E��
-w;ă^OSsz}�8au��8�k���V�^���}�|
-]��5�P�=9J?d%��Y�>+1/�﫜.�4Ǫ9�8a�'K������T�����E�����(�8��d8e��@���=pWr3���v�����8�R%kɥ�
-��:�K����w�V���r��ٕY&�Se�\�T	���g�퀎�Ю�#a��G��26_{gib|�����12Jw���YIpU��*��_��~��;�u������ާs���}�T�����6�E�\�l�����<[0��5���+���
-�s~��� �FMU�w��.uas�*�K���u�Up+��"��ҋ8�nQȉ9b
-�]J&�]�5G��J+�o���J��2�p�r�`1�0y�Z�extw6�D��5<j��/J��(tp_��'��9��R4� �CѼ�����]�	X�A�X�A�hՠB�ՠ&�iPr`�@^�h� !>�T�/]�鰕g(�9:�R��
-�hWb�]a1�3<����Tǯk��,T}��U|5�G�������OS>,�#�E9u&�r�y_�yX/�K%!yFL��������[����_ ���Sd�"�5��I��H��E*�v���B��t����%��|�I\��/-V���UK�B,��j�0�S���$
-�)�K�iG3��s �$��9IlL^��e0�����fK� �h�ʷ�`%�֋`���GTH-����&}#0� �/BUxbU���C��o���3������`y!��?_J�`'����`y������3���I	3~��2��L�$צ[�'��s��rv�G��0�d���'S!ZS�|X���P���K��85��.Q�;&V='�^l�s��h/Y�hG9��7�����ԣ�� ~o�q8D��A�E�zd���>
-��p�����
-�{IVE'�r���Q�*�/�b�Aр6���Zv��^��+DM�s{��¨�fld2>2#�$=B��q ��w��D������SM�Ô#n|�T����e������Lt<�v�{6us:�0?F<?WǙ�^T� [����(x�q<�S��_�
-�5x�%�f�	�3R\ |�
-���D�_D�0�,�Xj�Y��%��~�DpG
-�k2^S^��$�0����G�`)��� ��F�Z��J�@��p�<����!
-��+�x%mT��<Yʣ���L�Ey��l|H�?&�RDZT~@�nT47	�@YQ�-TP�RA-WA+���U+M�w�$6nׁ�z-��o��#Z�1�ңyL�t�5�_��[j�	��w#K��|�Ec)� kW}Ar�D�=�Ӷo�^���x���e@��h ��2�����2��DmPQd:w����;�P�
-����7�D���L���/3�x9�F�`K`R�����2G>ĄT�6Z�G
-@�fO�� <����k`�%����qz���T�J գR�ѥ�k����e� 
-
-ˣ�MH��-��/S�i�d������`t������ZmAx�@8m6�k�V�"��1!���ޭQX���'�x:��Dh���%h�b;�j��,�
-?*0��F�G��3�e�U�f�`��-�["�;h�D�&.��>����H��g���ޭ�K�#�����Њ����Ep����7z��y�4��
-�����9����4^d��	��Cp��>��if�-M���>��@S,�ϊu%��Ya�1��rQsC�[��"�G7�X���m��%"9A S��~V7��g��P?C�v�>A���@Hi�S�t�юg��bB��6�NR��	Pl�
-4��|�ϛ��8ј�05_q:��)���=2b(��6虌V��� r��63!d:�/��DL�kLk�FF���{�� �� ����G%dW(��n`�P��h=B�b[(�R��-�=?
-��Q�v�q�H�����T)����*�q�ϥ1���6�U���	"��p��r�
->�ߋ#�9U�f�L}��}WIc�K�NE�C��
-4�Sf<����n�Xq,�A��*4'�z~�b[?�
-Mr��GY1�KbC}D
-��*�%��n~�K�-����
-� |z��1G��)E�^L�&�$���8���ftC�O1>�O���c"�?8q��!�~~��#���	Ǝ?w)���!)ȝ���7L������fP�P&p�����C@^�A�cQ༊��6�C��'�a�`�u͢>�\J��ô~���V���-V��S���H�׃Rl����ld$�2=�x����z��}>�	t�B&h���QbxM
-���.a���M(hbҧTp���yӌ�؜L��pw�qx)�W3�H/��I؏J��(1��^��I�+�@��tW��鰲@�
-���Pg�1 �gts�0��0��m<T��,f����c�Y��ˣ��Ĕ7��@|E
-� 
->����?��o��(�hz������'���0�'��74655|��i��M
\ No newline at end of file
diff --git skin/adminhtml/default/default/media/uploaderSingle.swf skin/adminhtml/default/default/media/uploaderSingle.swf
deleted file mode 100644
index 1d3a0bb..0000000
--- skin/adminhtml/default/default/media/uploaderSingle.swf
+++ /dev/null
@@ -1,685 +0,0 @@
-CWS	�� x�Ľ|E�?�3���Jr���v� �q�8�;�;�����q:�Z�"�d�r�
-i��B
-�L+�idr�����Pwr�����`w� � i���!˔��<'e�2�42�\��{h��᪮x:ѓ�_(��0H17�a*��a�S�U3����|�٩xV*�b���ʂ��N����e�"�`g"a&�d�>��T���9%�u2\�&�4gCp��eh�lm��n�f36W"��@�[㤡t"e:�n3�ʣD�2�Z����8;l*C���O��6h;��O�gI&gg���^��3���D^l��]�p��C��a�����if�Ù]�|���y��!�7i�UѼ�a��N��2��I�XU4�3�H��k��"i�l��Q��4�¶W���m�	t$�&6�f.4���aRp��ԭA,�;�D���z(�LYƤ�i�B���Lo޶�d:�I���~p�lr�ń��+��%��:�,�U��Ț�pSg�)��͜�L&v�y�Zsend�7?O$��ZD�,�f"*+uZ��K��m�݌�^[_XM�i=����>��Y����N�͎`��'^u�"�G�Mw&T'L�p�r�v��X�l|���.��jH��kN8
-N��lf _�E�q&g&�+���y�p��*�hչ��x�HB&O(�W��nJ��
-���4��Ty��N�M��i�h�ՎHxfl� iC�����n�%�WhY
-���1ݢlڱ_C���ԅ��|=��NJ��m[��9�K*�څ���͠M���>�LO<���_}^2��/0��P�L�k&g��dJ'�%3d�L�c�: ����en�Y��!^ziC�l&�����Ʊ��Zv��f�&tg�T��j��,�a`�$R�Vef0]2)�;gv�(4�Z{sC�TWr���S���H2�
-l��U��y�Ja�g�-�O�*�v�c*r��|���|�o��2�[j<�jZ;�4�a&�V����K�6O�Sa��/Yw &�k+�$��L����5��Ob��fD,Gx�8-@Y#
-9LMv
-�Y�(in	~�HA��gR2��Р��
-s��+WCx��3f��.K�?H*�Q;lb�K�Ͷh�/]��I��������W�nn+"'�d۬1{�U�:�M�$���@��P*�t���[�퉸l�\��t�������tI�l� ��e�͋��攙�K�dٱ"�p�ǚ��G��Ԍ�����4�6s�\�7cF��$'1w�*7��e�!����h���̤gw�}&ƹ�4�|�~mIi�ǳ�M%g�ԝ�Q(2���:B���F�t7��v�;��X�%��^j�"�(�9�Ͳ���I,랉�4b��T#�e14�q8^A��ٳD�u�m�m���i��$*Օ�X���ll���h�br�k6KX���zfdk7��3�6-��%�'5R2�BD�Ҝ�?�y�J�`L�J�"�&B��-X�O�:��m�+�n��G����Q��΋g4A�}"ʶS���.2O�*�3��m<�sy�gf����m�1�+�P�"�]��I s�*A�	�d�k���ޜ�-]m��T�N�F�l�ǜ�[�\�t���#+�N��R-��oy����K��<���t�6kΦ� ����A�e�G48%V�|{�r�Hg:	C�]B��(g�=�����ĺSU��+���	�h�Ѳ������l�F���T:�,��}h2E�b��*��v��S�Wˆ�ƅ�gsM�H̳V$�Ikh��`�4��VaS;4H��EO�lӱ��{��j,�����R�d�VƊ�M�d��z�rW�hz.tD���R�OΤ2Y���������M��0ƍ�2��"L�d䄙��[S[��	�}R.j�6�"�8W���������3�s���"RL;� %��@��*��'g��g�An ���9���㴮��w[f�;�M���]�M�_�8���H~ug�&fE�?�˰R��Y�cu���+��ױg:�Z���
-�H�%5#��hb���������[dF؏>9߬��M�p��ݺ��2�b�v�f�� ���cN!M	�J�\�٨G
-�򘯜�\��Yd�=���?h��RrX��q���N�a�nP*����!F=FI��R�:<Y��|gA%�(�>�̷�TG��4��E��Ο�Ni��6���JD��4��<Y{�d���zSf<+���B����Z��4d,I��e��I��� �3髴��g;1Yy�kf���hW�g�ܽ�ݶK$e�zW'�0ӴI���Ϯvum�Ԣ�%9+M��A�D7�ET{7!@����	�Sv
-_!M��o����	E)��Nޝ����(:>�=\�PYSha�r��E?�IW�2��l���R����i��Lo����06��Ǌ�
-���P�h���=eS	U����n&�y!Q�;0�=a���*�a��`�,&����A3�{�1�w�
-�©x�����5��5���ʻ���Mm��':-6c�ʩ���fEۺ��E�M޷��r*�^�ΗhI-�D�Μk�v��h= ���N�m3L�Tڞ���XO<+�U:]��<<
-�
-L���\�b��E��R�o�װ�rUMi��a5�Т
-�U":�@9�4	#��ֹ��OV�d�'����}}0%B=������}F�����(]W[�A!b���cΥI�}��ڐZ�Fvq�Z�%��PM�9(��A�.����߲�6�rX�XE��)a-Ws/ˏF 6���PL�!��2V$�^��--����%��9#m�����`�4��K|@E^�lF�n��V$5m�gM������9�}Zw�>����"�Tǜ5���'ǳޑ�ޢ�.�e�a3r
-혗�
-K����'�*���e�[5�v�������=��ȡ�EJ�<�o���	o�K��'mVz9q�|�(O��Vе�i=��˭��8߁
-�g�W�{0o\�^p�H���bɲ�d�3��L窰s��i��'��J�-Uy�}P�o:� Un��uZ��}B��?+��w)u���'Ӷ�6�=q�yr��w�E/{��t��b ����)w��2�7;�LӕlB$-Yo�����L�:7��'�tuLjH�NP���v}32���֐�
-B@e��@2-=�����*���pk���3�4�s�X�r�o�M��4V�h�%U$ӽ���M�[�����+����>��S�,�F>2q�ر6�Zd#bu��*\�:/L�{i�̈́�`�o�
-�Y�
-��+��购���2;"T�\�1��8O}d�Ք�ogT�2�0]��Z�٧:���V�<m��m���t�i�{���tFL���8��-}�K�����=NIz/�C)�/g'	9������<D+;D7�lW &#��Qck;`��vZhN�Β�iG"+�Y�S��&��z1ټ�[e�'�En��ۺ�[��_'�o�|.��|ϯ�oEz8i�4���(�s`�=픹ܤEW"!��
-67<hv9JW>h,�%���ƽG��m����f$-:�A�JZ�E�Q�fnq%�G�Y�Æ{�7�J�̛Ȫ+�q�=�,L����^�����/����4%c�
-+��A�����[6{$�7!&���i՗��.��T���-�]�v�ǄR�+���h�/f.��kV�*��A;PY\NS�
-����92��;e�
-ُ��>Q��N�n�ܯ��c�9{u^;��^l+������vm�$*�*KZ���~�]���B���e�������s0�٤�h�>��)�'��Mm�ֺO{g�urwt����&��׫��wR�N�Y�im�g�s8O��Bn�Fڶv7u}O6�tS^չeOkG�3ftD'�v��N���y����NZO��Ly3����~O��}Ps�|n�F������^Ƀ�6���t�p�]J�rd��ֶ6
-����uZה�Sc��m��O{E~��Fh�� 6��uj{M�����Nx�F�,:-��<}ꌎ�����z(��>u�~�[/�'���F'�b(Ծ?2uu�/�9?	sm����n��-�����#J��4{y��2�Nkk�ȷ��8��ؙ���U^7����֎���;��-
-ɋ@٤����/mt����!�DT�#�鄶o��]��貄����B��6}Z{���b�䙝]�;c3g��ʈ�s���)C�B�([���i���6ἔ�h�j�P�t]R�(��iw���ݵ^Yry\�Y]6GP��vJ25��'��H�*���3���_ٲ0�s�>�/]}3+(ߚM���
-�;챂tL��3�A�Z�|J�����d�̨�ї�fv.6�1��q[���#o��=/t
-R�/2��a�!L�i6{�5�<����o���7�Ɔn���[�ŭ�Z0-X}�-� �x���\��-3��%���YSZr�����-;����e�F�HX���y���	;�~n�]��x�._�t��G��B{5TX*��*,�Aר6e�K�P\���y�Fw9�9�5+a���� �C��D-/��}����
-�&:���#�?hvOU'L�f,���:/�S e��S;+g��F+H�ҳ���}'�#�n�.�rc�|�%���?i(��������(�x��L��u�p2W�M�Z�|$�A��<e�NL2�Z���dy����Uvm��2����I� xl\7�M����P�z�*�×�1G�3��Ϸ�J#�itTn�������%��|Ϡ�`gHb.${C�Jo�}���k&�\OCRA��э��N�Yl��9�o�-��<b��8��;VU�k���)|�K>�_p��O����̳��b��E��hܛ��'{����|Q����}����p�z�q%��}s��}�	������卡����n��=\���I�#��q���5
-)t3K�I���(�Q���
-[2�e�iqZ(<�#�X�T�ůH�/SG�/
-7w�Zf�����Ӭ9���9_>�'-D_µ�A��އ��_�7>��'O$�ώ�c��_v;~��K���۪���m����>e��s`�׵�,��RG��V���|�񁔜�����l,�z�.0i5���p�:��Jd��?7�ydS����xO!�f1zY�
-�x_j�x?��l��
-Q|�]�GZעg��GO�]d�쐭�eZ��P�{˹��T2}�C-c���F�RH`�:���S�4��-L(�n�N�ξ�����pK&�n�1[�A�Wn�Zz�[�,�wK*�+<�h��
-TQ��$�p�d�?_�6#�$Ӻ|�I�t�k�Ke�۔Yٶe�c� ֡lr>�uλ\57)3?��i�tD���vVIkύ #/d�Q#�2��Rd��3"tg��?!@�.��7=ko�i_#�`�X��Sa����g	�;�
-{�H����p�֒�k	A�Z䞩E���!i�s
-Z��a9� �>B�}�-x:��^�O��1:Қc1�~�_��2�4;��w�K��goz-�ʱLmᗱ����ח�C��NF���2MU����~�YfG�	��Cv]�iÒ���`n�G,�`ȓ�xJfc�/�`�!�c��ȹo�Mo���=��)�-�C�q)d�ôй\KC�����<�F7%\n�~�yl���۾%iO�a3�"u��I��؀}��+�,�v9��K�V���g[s�E�"��V�B,��}� ��?�_��}�4��^3���<7\!��~MM���L�󛦕��S$%8'�靃E���a2�N3K���*����Z�$ذSapxFr�������/mLk��|����_��q�ر�$�����k�����kNڴ�*ں��s��T2nɟ�?i<�L
-�}�b���o#v��g�Zz��-?��Ou��'$�Z��)o�	tg��c�s���
-�ۢh��Za�����Z����n%�������2sVL���3ŹS�$-�ɮ����⩖^����sa6@{y�{2�Qz�{�ٲ]��ȟ5J˿ᾓ�~l
-H`�	�)��6��F&tL���P�����������O1�c8�h����)ܿ�џ���4�E|�0���+�5�o ��C��p@<ƁY��G�X�AXXX���oѼ�C�).F���#��@�||���&E�2�;ބ},�i�qps��xd;�٢y9�8����2�l��Hr�+ �ÿ�>1�8��U ����p�-#��������B��9p{��sA:p>����� #�%p/\�phW"fS�Up�`F�kw-⮃{=h7 0�F߈�M�g!�p�ALA�p+�6�0���#��;NCZu�wý��CZ�p?� ��!�ÀG �<��O�}�$��?
-�x�Ҽ���o�)6����p��b�w����h��ᏹ�>4���-?|���K�W��� 09����;.�� ���Gr��[�w�
-� ,Q���a���pUD�P�v�*�?p�x�	�-W�ߢ� 3�Hѿ>Q�V �R�W���XX�8�?�9*Di1(�σ{>��~�*�/�{1ʺ��\;_	�
-p5�U��U�~�*~s`�f�h�ѷ�ⷷ�b��(�v�MT
-xM5�#�����MUL|�6��FАg�p����(g�G��A��������&~����~
-ᣑC5q�c>�qp�G:�a�	�/��0x5�$���ē�����;
-jm@��`���������}_�
-x
-p4`����� ����w��u����Y�޳N��TݨD
-�A�f
-4� p9VB��X�<����e�"<�P�)���AVU���z��H���p@ բ2Y��tf{����S�Νd@��	WP�ʑ��r%HV�E�����L�ZQ4��:T�j$��⺦�X����)A�0=X�p�i�R��jm"�U�j���<u�ѣ���i��VF�I�<o���S�IÄpQ�� b����;X�@�
-��z]����q��T(�ǃ�Z�2�sn0Q��N��K�Q����c$K��<��g�� �49)5�X1ݕ-_�ހ�[N��Zc���
-1Ֆ�hJ�%?-���!4�t�OR�����YWb(�$Aڃ���|>9tA�fVM1�����9��٧�S��
-ht�Ҽ(���%����읭N�)���f_喎�(?��Tܣ����6�tPA�욮i�̙��"��E�Z	j��F"�@�pE9舲-Ƥ�2Y�V�n�'zѲ��
-V�ކ�l��K�˙V�)۳-y���DC��Y!�:���ש�����=���QWF��-���D!>_�o_���+G���ƌ˥ȓ-��c4wny`}���x{�Jq�v@6m;��)\��a���� �d�R4����/����1MuL���rq�l�vF̖�_�ek��\ީx���"�o��ҽ�c�q�|<�
-n]4��-��=�X�m5in���춓L�H�%�5��&�p�ɒ xR�p��[^��:�g��U��˥��P6mx�<�(ɛ�����em������^�i�pM���l+W�ҟT��?��ݣxU�P��	X�ῧ���+�y��	{�gϑ����[�lB��x�]�
-ae��1b��k�)��,�4��������tb��#mA�E���
-cƨ�6��-�x��MB���(r�9��_�:j��i�l��
-:TZA�J�?���/�n�+�
-}�Eh���͊GY��
-x���z�����Oa�Qv�|����U���E�J��VH�i~u[GJP� ;�|r2R�{����i����亂�o]�m]ɽ�H�H��I5�նAO����K٭#
-Ҿ�^E�������4{�j�&��-$}�)�0�Km��.�X�޳�>:q=�@v�CY�G�>�}��k�'�+��Hs%����爽�}���K��W��˾��1�
-�gWr���b\Ue-���5�_�k�׳��b�s��
-㕊�f>ĵcs??i���?��G���%>�������|9��'!������O�5~*�O��T�����Ay��D������W��<��� :W�E�&b_䫁_�g���P�3?��H�_�d���� �G�\�O�y��:W�����/Pi��C�wAQ���5���W�_H'�E����b��(�q~	��/Uɸ��_)?ê�1ƀ��.Q/y;�HU��8^ծ@�c�+���W�^
-}�P}���q�%j��H�z�U��G��v����P��V��z�nU
-�=������}����_�> |�� �U�CH�0,�G�>���q���'h�oS�'�U}
-�f�i�[�g�ש��]P��,:���ZwC�U�9��~�y� u,3vc/���e/�d��,9�
-�yJ}x���=������Ϫoʔo����6���;H��q�]P�Q[j��Q���E)��+���w���>/) ϛꇒ_����1I�����rlT?���������o���!0�_����%�W�W�|�~
-}YÎ��	���)����l�>�J���/����}	����"�k�7�oP����G�߁��=�O������O��#��,���G���X_�Coh���H�J�/�! ��O����i�"�G�b���À�FTe�~8b��?Ľ	x\Ev(|�n�[uo[vwKc,@X`z��a�$���Fɣ3���I�sՂN'�{?��$/�e����+��[�������-����+x�MK��a&������[˩�S�NU�sji6r
-�}�Z{���/����W�*�mĤ�� u�vb��wj' f���������f�A��O)[�� s@[1۵9��=B�W���Z�M���.�{L[��6%m�**>�\��(�\�Lp�kgA�:�͓��j�$�(T��(=j���Ք'�+5��)�~I[ ���H�?���Fޟi�C޿$K��]
-7�e�6�C�k�-ME�w��zI�"�?B/� �آ��L�����W!�h�[������Q_�ܥ�w��r��6 ����rGi����7A|��܁�p����׶���
-�}����^	�	�<��__��|��*�e咎M n�>�S� H��#���C�=���.�Ȫ@b�b��r]g�t����=�R�>R�G�/�����h ��OўP����ߕ{�b����#9q���WCL?>^�L��ND��$3q�S��=�W��V�i�m�	�!������2�k8����|��l��9:1��2�+/��S��\]��� �)�ya-�h����\^�{|@,ԕE6�b�l���9|	���R�/���X-��8�`ǭ �	|%Ʃ�*;n�]��SS�Z�qK���|�3�zz�CUf�����7�R��QS�pk�
-H��k���7C�~�,���^�i+ൕow��j� �󝐵�=|7�+�p7���� u	��� �y�� ��|�S�����n�pw�஁\��ʧ�2�1�y�[x3��!p���]����w�.Lc�)N�B��D6��uX���\=�<�?��� ����6�F���ܱzJǱz�3:=����<n ����}��p��/�{�
-�����:�"a�B�q~
-@G������+��-��9�ߕI��Л,��G(�����L1�b"�2GLw��15b
-�S�{S+��:� [�i��-j��%�C�<1��{�x�h&B�I��l<� ��q���� �¹�"�A��h��W�Z��,�C�JQ��|V���[,�()�!�M��%��Y,����M�L[{D=��F|`��6�������.V�	k �K�D�A��rTφ.]/�A�b=$�q�8Rm#į��ܛ!y�X
-�a�6ۆABo��d��ۀ7������ڼo_��l'Å`;�&���vq2R菳=x+h6Z 
-�R���\գV]ֻZU6�l�4��B�Gu/�|(�QUݪ�:�]Y 
-`��E��Pv��>U[m9����~//̲jwe���H}x� ����с�q�\ _��;����t��[x7��6�3��]���~��~�d
-��T厪��l7tLs�w�|և�A"L\����{��d_�A�� z���b��L9	°�7 �sI!ujI#��� 29�h,΢1N�S4�z�E����[z�[˵/����$�A7oA}�vH:,�.ꁼ:�x�^�z��0����糵����+��z���{z�`�V��Vi�E�1W��]�i���c��
-x|�vZ:]k���hA�΂F
-�u������D<o��'��}���L^o�G$�҂�8*H��X��>d�fA-E# �X	�~�0�A(ǅ^i@�U:f���iq4K��t�:��3�1���Z�v^� ���zV0�1��s��͆N��C�4������"h�:��:�]#�xPG:��zC�Q}S���D���X�Ga"�>�PQ�_�	�U�����D��"*
-�S�*T������3S:V�b�G��SSU����*,�Lɟ��5�-�������J%�S��Q%i?�E%��}x;�����*�S=�����J
-���y��`J��*�0��e�|��S
-71r�1�#�teʓ��Ĕ�N0� �Fj��<=V#�4�t�����R<M#5|f�F����F�<��n'5rP{�F�Ct�F�dʷ�j�Ly�s���ݿ��r����"��A�N�C����tr
-�å:�@�;�:i��wW�0�2�:��(�g!������28? ����NF�L�� |Kt�!��Ȕ?�oD�	��/0����̃�+ �m����皘�ۿ˔��������$8=aI�	S~+��R
-��g��	S��?b��Xh[9S~1�H�)1<�.���c���B�ɔ�A��{���=A���� �!�F�A��������19�o��9#;� �@8:� '��a���w[ty���B͆ѿ*|CI>��z')�&�^�I=�a���I>H�A
-ߠ�=q��I�'7m:����@ԯ�"��M�	i,�D�F%��\C�ا<4�'?����s<y����7��x�"�#]K�Rv�C�ߪ�a���úȫ�P'���j���</5�j�T�ԛ�ɳ~PV҉S4�o �B�a��)˿��DQ��j���;-PE).I{�h�T����픖�r�I\dqN]e�nA�˞�$.1�)�X� d�ZR����+HC������-�D�;�[����;?����S���I�C�"�:�-�6	���Z�4C+˙���,�, `T�� ���[�u�..Z�}��$\L���F8}YP(
-f��%���4�H���ҭ\���wHg��������ZXB�a�H�}�����7�XYb�x��PXe��hݕ�87*��if��b[�{8
-�ܳ�N����m��{���!F��x�qJ`j�M'Hk�XX��fk-,���)��e����4)�,UY��`B�kq�xU�I�Ґ^��xAc��0�5���΋v��	*�B2($�BF`3�y�����5�4�6f��G��D5���(b9ZB�(��N��}"%0�����5R�e���  � ��Lt���Q�@d!DB�cd�ZC��(s�u�*���v���j�����Qom5��]�� ��,uSBU{�~�莇��=������ ��h��X�$]�lD"L�yxC�v3M��h��$�(
-?u*�'�U��\�!�C��|�P�y�X�}E]� t��N��.���Z����U����p���E.��0�_GP��`U��� �J|�Æ�u)�pٴ�0�΂C5�.{�"Fu���i�VN�x"e�6��D�M8�*��8�&�h�-K
-��$��]�5�1C��rؽk�7$��B�&��H��Rn�����h<+�Z���H�V:#�ɑ�)h�0���*[2{�����ˌ�jo�ɤe����=�:wdDV�"9�)2+��1o�����l��я
-�1����%�[��6h3��gڲ�C�5�R� ��֐J��*��eRB10��(.��	���־)���4-����\���٤j��%��c�
-�\]�Л@x�%��w@h�3��Bn�
-��j-�k��
-/��B�%�2�>n@�i3��Lǭ--i�{
-�m2�'ҫjmq�z��uX��$'
-b[i�3�g^����A��H����ב(�:���j�QXQ\� ��+^.� 2k�1XYZp�L,`��"�KXr�Ӥz�I��b�$z��"J��X�8x�	����ep�������l�Q's)�ͱ����v��k��c@A�� ����9���U< Z�2 `1ir����`$�e��vl"i��R"�C;
-RNB�mB�	��z�!�w+7ek����u
-�� �A#|� eG���ɰ3�м�9����:tV;��E��Pk�>"��>�$+�*�9	KX�^^Xj٩��9`�����Í�o��
-@��lx�<a�/�li�26&�)�aO�r�!wH�����;�$L�?��ì��`G��*L)�U����x�����38����X-I'kI�zdΉ�GR�GHC�P�&��,�6#��K�P�
-�Z��2dm$eZJ��u��j��@�esԔ�c�`�5dE?N�L���5d�>��� 
-bG��02Fu`�ga�F������29���z�D����K�F�_E�6F;�t�%/�L"�6��|�x����\`H�,��o�
-�۲Bl$o�ɏ�":��"��7�^�����"���`��*��N� �Wa�΅���
-jC��A��Ǡ.� �!�M�^gҰ�X�	2
-|Re7)|�e�4z���,}�(�w{0ET���;�� h7Y[I��1~��v+����7 @@��I(���O��iT��U%���^��lAc=�$l�W%�v���6<�`Y
-���+�D��7���˿�'"Z."����
-��4�Cn2�`d2�注!�JM'�������}��d8-��r�qa�l`�����]4����m��͉�i*$$��"�M2�/`������-�e�o�
-SS��?3��6(!�'��+Yʬ[e�TNI�R�� .��^M�wL�fw���$�$���3ԉ
-���8�h��%�M͙"���--he;Dt(�u�NM���{ >�fcS��*Ll�Ņ��EVZ�!`0����A��\1��Z�$z�s4GA�Pr��p4�ًU��a��&I��z�ZL��nW��L�B��x{����	�o-�@l("�"�� �0"e�7d�8���}��Vb6%�H
-�s��(���WGƭ��#e⪑�mW��n�5����Ozp���+���qE$rݠ~��>�q�\�?�=>Dbob�dYW
-�'���}@E���M�T�s���� �)�='<K�|ԂO��% ������RNɆ?d/�L
-�_��&���FK���\����@���0�_�4�ۼ�ߑ��026_~�|a�����������6n��R"�c�F�C ��8�[�
-+����:�&��$�b�)V�`_"�4�)�"}L�x���m���J�Iؾ�򠽁��ӛ�&c�A��
-�S�L���rƙ�����(����;�~��p'�S�7�=���kFq��|5��ܦ�A�&wP�Nyơ٩S�.�G�*�m�Y�Ʀ4|�*��RΓ�.��t�F��	����f�`5z�Z�&�.V��u^څ�H���=PV�x�������
-a-�ͼn��@���E�m嶭t�0-��|�&��`�"-Ð����;ጰ�'�adP�jaͣ��a5�z8������vI\�V?5�ƭ�9Em ���RaU�W	+#���x���?�"��	��^k��������0:Q���E<�����y)%��>�@�j��^�yX
-�]+����՜q�S��
-�d����ef`zߘ��֭���a)q�6�-b_KKt�l�J�-�\ ���O�9�-�� ���*�W�^���rO45�B�햔3��r_�,r���8�R-�D��3��I������=[�YiBc�!�!ٴ��gk��c E��(�~&�ϲͼ"�䷽�M;���މ���K8����ps]%:hz�b��ͅʙ4s���
-ҟ>����o����L@���:.������A�z�V����{)�HzLbXQ�,��ɳ��y�)$dgG�#T���|�}��ap�]P��Z��C�>*���5o	A�}��|���F��� �Zی��$�_�>G���VL��V�I���F4E��`��H*�u�FF��Z�&jD O߭V-{���(�.�,�E,�����o���R���0B�Ƚv�4�AL�Vjb�$�
-�˺:�4�b��I�6N�Q?��'��V@��X�C��X����#�z�(��R������)�=q$�Jzu+��̱	An[����������v{-����n��K���x^�P����v��B���F{4�0���fx�I�$�/%�J� �mH'�oq�������7;[�Z5ξغ��9��Y�뙎/�o�wgT�;����\vQ���A��F���q_H#�wzD�6�a�,�a�Mo�?3�Ӽ=��8���Q�����9;�z�P7���%�.�R�M"�	�rJ��3g�nn��� �7�H9�)��h
-Ɖ�lAz����`4(�D��¸��-���r����v,�5Z�H�$�h�T�1i�X:Q�&f�0;�=[���y!�z2f����ԉ F�ݻ��r�\u�F�di�f��0@������Id`��xE��n�"�T%#.�F�~*!�������uL�q
-x�H�y[�\T��)�kB7Ź�Ow� ���4�6g;�?MY�VP�/�ɋ���m�E[�4Ҷ�a@�Mx�!�!a4��'Ѷ��L�"��IV�$�N����A��4C�3N�ﺦ�N�m8�+]A�]�+(
-�K��33
-H�䀪Z�:׬���R�@�D�f�DR�gX�7܄�
-[W�����lQi�~�]h&��،|!��
-X
-qr�9��"2K#~��2�H�CA���u�YSp�d��<h��3�h0�J�cw��K
-޿*	q��BLFBL�H��@��>�+�!��}#!z�Pa���_ș1���U�Ȩ[%ӡ��KRis�p��L�1ju��:�#��i��%�~̀��,
-���BcAa��p��|c��{A쉧�9^v��Pi�Hٛ��o�6������m��(� ���qԊ8J�h��뒗pt-��zI:�=��"FI��~�Ay�*:��"s�Z=�����k�2��@��Ii�0y�~��̱b04ھ�{h(���A{�=��R�{n��m{��+�c(��Q��0��ۃl�����kd�I�\Vt6������a�,�ThHk#�L�l���)�h=M���6�wղԩ�9D��Zj����2�jPK��k%4�,��=�����"��6=]�Ŵ��
--uB�UC�atn�Y�q�w!4��!�BC������9��hn��'w�}B�����[��[��~���-S﷼�e��������[��o�[Z~!��j�gU:l��~�Q������x��KݝM=��1u�@�b�M��!�3OiL5�H�W�t�nR����1 ����j�OB��WVQ:n�p��M
-��
-�c/e��6z�M�����o7�3@a����
-+��Ө��+�H��A�h
-��S[nf��ٗ�@x��tR��R\"o���C��<�N&���̔:�d��u���'���ȷI"���r�v�|�
-��-��d�m���mhhi�v�4��[��
-SQUe%��*�$D:(�d�4�lrq/�X��G�|���l��;j�nR	F:�:��>AXm���C�>�A�|��$y��y-��-
-�)��&zĖ��h�OZ��L>ZPl��xK�.��P�"��wVvp��~���+�T.��U�3�[I�Zr%qI߭\wή��4,D�幭�e�N!H�������,�q��+�{��|�x����"���V#{�߱�e�v5���x~4x%)�B���T�3}��������fF{H9��8���\ڃW������=:'�:�3�����r��t�m��/����7]�L�r_\ǽ�/'�fO ��[Z��(ި���w�ާ��^A/�p�)q,��~Z�n���qVg.�S�Hsj��y
-��q��/�\��,��6^�^K$^l����6�8���@ i��;�	�P�5ا�l*-�Yd��ulni��
-�U��?`/	��keLw�9-#w����F�5.Nm[D�m ����������?��=�z܏����b�jJ��e#�t*kВ�U�y9�eOu���5�6�'���'mc|~���禂���j9��ɤ���2�j�5�*���x��	��vU=�%p,��y �~�$��L��L�dz������`��^�5���f��n��Q=����[��V����� �qG�^9��'�2��i���b� |�ǉ�J�OE�qXg�����m�-�Vq1s�Uq��?�0ϗ/<���ǂ<���(���RB��@,�dZ9��R{X?�a���V
-NwkM� �yY�� ���X$㰈�sr16v����Tw^���#��;�_m�$l�$l��c�zO�a��{����=a|rU���z*1L��VU��l+��F1j��i"e4�fx��� |�/��({�)=����ąm�Fخ�`���k.�o���}&Dll�Z�.��g��9 X)��0� kpY�C{S���w�T-Oe'�}Q6&�ZaU�^\΋�E���������n����r�?eqPm�l)�?��(���Zey;<�m���}�Ci�]� P\���c� ��(������� �������:�F!�|�"t��{��*}&
-*/��� 	ґ%*}��/P��"�	��x��@�{���OP"��jN����L�[�d�T5�;�nDF�	hy�GvI��jOTU�i?�"R�)�T5[�@�:C	"����B8ĀH�qV��g�"_�h�J
-�	��^5����
-�j�'�+%w��i��h�DJ��)�#`ָ.�Z�-��˾�_^vS~E�
-|ʾP��j�=]�U�-� ��V�Qq܌~bڞ�뉞pc\O��s����L�4y�q��5�Yg�
-���]<�rݴ6ڻ�Y�M�k���*@�
-������.�/ODk��5�$���_�����g�s�2^膡<�T�'���I1�q��\��W	p���} 9l 6x�<�;��M|�#��4��+ܠ� 7��xB`��
-��
-r�W{��F�U�/��P2��I��E�kk�(��Z�'�Xr���E$9��ͭ��-�Rz�YJ�l�R��R�\�x])����Zg��e��d~0��;<��z��G�z<���9�(��U�U6�V5�C�]�|����Z~*�79�ew�l��4k@c�m�4G�L:�XP|x��A�6��h>vV�6���Wv*�ԭ�S�7�g�-� ���
-�:(�I��0�B�Y�KY�[�����|�r��;��e]QHy�q�%罦v�{M�aU)I7��ô�����ה�1?�F�3�T��^q<�+&d�~��?V1�,I���k
-��+j�*�Eɫj�"�ɋj�2���؈S��:ǑrG�i/x�g������1xN�={d	�j]S�K���Z�q:�d��J�C�B���\>p����&����Q�
-�x<�O�E�Ra��]d� JJE���NO����n�"�lG�����̫�����R�~��T��������*>Uф�%�����K��T|7���Ͳ~�8�ZV%��� �uW-�T�����Շ�SA�|3�V�ZDgLǣ*e7��Z�¨�IÃ}^R����!���y����p���� ��!
-
-k<�U �*p:����1�a�!�����Lf-`��ɰ�g0���/��@�����PI�YlƧ1�6?�=�1��c�Ӟi�V��_�8��2��c�"f�fa��f6��͙�a>�n#�mP�&�LG��8px�3��Fk�� �`��0�Y�X��WIYB�V|B�t�(K����S�{�u�0��ߨ��w��ȣW�X*�K����V�@��M��l�ˑ��F֝�?�62k=�#Sx���p�ɬ�L�_��DoMl�����\�bS/|'R�Z�� ��H_��wWe��5���a$�V�ᵌ��ew�su��=Od�O�f5�U~{E��v)��\>r��8|�����t��r�B>�W:§T��P%[Z%[:�L��/b�U���r	��`a�K��}��o?�:-"��Q�n!�Ӹ��_��UuU.a�r��;��U���r_�6�kJ�v�v0��'��wȲ����Qke�����C��S�/ϙ���l��1��vH��
-G$�TY�;���E\q0��WlUj�x����|���+���d�K�����v'e��F����X��|1�Y{0��dQ����V�T�Φ��%�spg�s���\������*N����j�{�����TDEEq�qw�*�v�@�E��g�.�y����:y2##����Ȉ<�
-��/�^AN�u*y�\���W��2�z|�=�T� �7���@w�	IiBR� ���!��/a���R�
-P��2�bB��$��r�� ���U�I
-�%�"���)z�$Dp���)K(
-?�uO�hk�O���j������� ��ޠ�����Ѭ�"ÞR������]���9Q�hv
-t,W�s0V���'��A��ۀ��X�O��۱�
-�* �V0U�z/+T뽨P���BU��שT��?�w��m��gk�UvnpH��2N����>�u�y��7a��C�qx�෭`߄���H����֒�)�x�oJl��k1@�;U��~�xA����0�~���H�
-��-���??�r&R�vh�@��X0�{�4v���h4m��N��˲~�l�,Gʲ�A6�r�$��d�$G��~�l��VY�Y6����Ra�)�E�B\(�%� �� �0,-�EB�B�{%+���$U�0b4�/��
-�
-�_)�F�zF�:��J n#܉'C��p�ȕBɸR�\!��+����������T�r�^ᓢ�r'��
-�cZ�q1v��^h�V��Zm�@BX���_-���h	+$\㈸C�ܩ�1� �pJ$ x<Wxf6�~��+�q��D�uȸD�-�6��	�վ�������2a�q����\�#�������JpXAW	<�����y�бI�]%�oR��ρ
-&����4��@����%�7�Br_%�!�P����'��W�_�H�q꯽�WeHC�>y���˙��s�`2�.�E!h��E���"��z�nv=�@k	�E�o���8��n�|*�������uH(� �+��'"�X/�Y��c�_�>78�x�ʸ͉��i�\]��L�ltŽFqw��By�t��@p�\pCw�n���{���q�=Op���6Hm���$���Jq�
-)Q!��^"��A����BPj}KD����ҋT�#n�|Ԣ�{8u�b�B�|L��w*&�f��S�C)w�&�z7	�[}�[}[��z��~c8����[��MB����P�pY ����'!X(4��=%p�'Ȁ�y���Z�^��]�W`1���5G@d���L����<�%�^j�`[�u�h7���B�'<��QT���`!)�>�h��j|���xz����������|0l��qr��0�r��ڀ�q��0/]3<T��N_9�j��ou��#�֘ǲ,{IP�	�	ś��7	���%�Z�T�`��p�����˖[�~� �:�[\õ�k���Qt�v���������L�@�E�mCv� �N�6���e���݊������q���>_GZ>_��w���!�_��%�\�o����H
-�5^rP��"��
-��T܌�����L��#�T�~�T������},u�p��\��#���Se��c�������!O�h�V@L5,}-��*��q	r��G\�����ݸ \S�r
-"�[jo�6��B�6!F[W���`Z����D`���G����Kk�zl͏2&�n�%a�`z�}�<�>$O�ex��j$�p��U����&�O�U�t4j���-M��n��G�H��ۄ���^�G��q�P��}H���)蔅�Y���߭���r8��0���2�>WCet�*�Xv�ȹ���
-��&�56	���H�eN
-G����l��zx�@
-
-X� �;�6���.�����f?�c�k�Q% �
-�+E��mR�3����Xe�qd��V�?�"�5�i��J��	�q^��b��,�`�	t�����l� q�R�w��V�A����zn�EW�x� n)�KE�1�+���B|鏯�G���v�=��F�ģX��a��e^QA�½"��KV�����e�@�=�>�=�VR�x]_�nB�u��۸Ꜹ��.b��a�a@4G�U>��l1�ž[Um V�.��� "���֖�,���5������a{=��Z��v�M"���X�S*M������<h#X[-�!;��j�a��j���먂��|�U���ap���o��o�F�
-�_��F	�NQN?��D
-h2~�X4�;���"]�ˢ�
-"݇��]�O���B�a�4}���b絑ߘ�٥��u���	�b�[N=2i9̩�@V6ej�2}�0!4?�o]��o����mbM@�%�G(|���G���(��	v9<�n,�/��
-	��G:[�i�������R��|��|�3v\�ي�؍t?�'�:����^j�	T�+�^WJ0F���j�o*y�XT�
-�٢x���)C�jl�:�r�4qZ�V�x�m�y�w��$(��v�r�E|�نF���P«���b8���l3�U����}���Qcߩ����k$\r_��%]
-��
-���c	li��G�!p���a�O�^MKQ���2w|F
-�Y�����L2W-��X&��W0U���*��У�����ȳ>j�p������
-G�;b
-�?��5"�,��,M
-LU $�-*����*��|��q!�-&����l�ul�[��Nl7`#^)@1	�:X�����(�B���Bx+��y��.ܠ$$�1����,��9�jb���j��^�|K��)���	r� ���&�&��?�Ce0^k��x�	�4����û�pm�@`c�`x���*:1�_��J���׼�ռ�+�d*��rAޥ�^�ٷ���PD딉՛�Zu��%�w�G�K��Y�2� �3}��id��>�L�����G�O�G�)�ֶ�R�	�/q�6�T��<>2�����<�]��
-�"����������sEx�,���5�_�>F��_|B�
-
-��؉p)�v�D����r�y?{a�����?�����4�e�o���Ke�E9.a�\���m��)7�#�N�K�~�E˗pZ��b܄�v�T��^�G�dF�m~<�����S�K	Q�ϟ
-�v��U#���5�ښ���<��&�hz-��x�����8c3����p'fXae��g��q�#õV��0�uV��xx92\oe�3��2��3�Ӹۑa��pfXee��g��q�#�j+�F2��2l��iltdXcex�'���4td���� QZ��i<�ȰVG���$�����������l��l��l��l���,�g����=�s<䌭��|���K�s<nb�E���z1��R���{X�=�h)��Eo3���r���+�ai ���	��[���� ��A��i��=ߠ���At{T�D�\Œ�<FHh,�.*%�U�˵D���WůЊ���D��J�W�$�M�&���9l��*'��y�YN=���i�r��s�x��~K$�D=+�>�`�k����[��6���&W���L��-��-��DӪDc��Z{�܅��[��6����i��Հ��٪ǈU���g��V�Aa�X?l��P{��	M�*h��5&���=Ί�����a��Ʋ�c�̮���K��!�'DjZ-�*�h̰<R�E ,���4P��X�[V%FK�Z�� S�h �	�b���1��`� ���Õ0��0�Lv�n��g.^�f�2�����������^�pq>�Xbx��k���wl�=ظ�g��߿
-�|�_��:�֠
-�;��:1v�8�j�������5}/�X�/e��'�����;++4�,��V�Ð3�ju-� p�]��c���Ӯ�7-r�5���}�s���3����.ɳ$�`�J���#��W�m������P���|�W!���5B�������-��z*L	{���"�+}"�>���
-]���������G��h�ԗk1od�;�x�.�6�{���^:<�+�;Z���o��X��1>#_��1���@Ʒbd7F�#{�Wd��MK���$��#�?�Y��!ޱ v�n�xׂ؋�Y{b/Bl��^f��,Y
-�(~>k������F;Cߨ�^��#ߋ��E�Z-�F���z��3�Gd;$4߫80�X�ޗ�X���c����YAӈ"<�3��N� �t`W��PT�K5�_��W�
-^����[	}1pE]&K��$��܃k�𫎝�}@ݺH}�8�B4���h��:-�^s��w4H�k�P�[Q2�h�
-�6h��Zw�k@��Mc�'�[���g=�rv}�V���{ 7A�n����F�ήo����-v�ۤ�� y	R���Ef���8���Gp�yR-�'�oSʬ��Y!S���v��Hg��E~v-���v�F������?rv-������z�Fg׷ktv}��Gy�kt\}��շi�m�s�F��4<�ި���D�QdW�r��K�v�k~��(��oJ��!���}��uH9�W��k?�~L��b,4��-�H�=<����3[�Ď{��=�--��b�}��c;�>X"㹲)ޯ���f�@
-��˦��Ϊ�S�������&D��� �-�ێ?)�R<�և5dE�
-�I@��,&����]�ƻֻA�U�5��NH�aB�yf\��	�O^ϓZ�%׀(��R1�F���j-�j��&��OiOJ�YOJ�|���{d<\�� �JE�Q�{��Àx�d~o~��>y�Q��3gأ�}2�50�_�NZX��Sq����G���Ct�kW"��F�`e�v�C�i���������*�����hj.��u��ԣr�(������N����H�M�Xc�T���kg���$@&}�ƷĤT�Q��y��%��u0�E�RE�At=�n��?�J����R���yF��gA|�G����(��"$~��A�m���O)�;%�x��[�0t����v��EN��֋��%M\��n�P�g�ߤ���9P�и�s��z��Z����kd�Mu��y�m�A6�}��8փ\:Ď�JPd�T��!�cl�ȉ��G.H5���5`��$~���&�t�2k2Y/A��Bs�>�#}l��f)� <�"��'��2Z?M�Ci�U�+ѣ ��=ˤ�bwm̬V�K�K�-��b�k/�&�����J��0CV����U;Ƥ;��g;��g�n
-�^�G]��Ma�@Y�_�<�����h%��$��'���������q
-���zߤ��I�䓀@o��o��?dl`y����{JF߀��.�	����X�F��i�@�q���7�]l�!g#5�s�Y3b�\�Ԅ@�nU7h���t��C�1<$��hS�8;y��{H��dt��~��3����;���(��*Y�6��#΁VUs�e�����{'���qz�,>��!���4�O�����jL��/�Rq�o�o�V"`2V��v�x���}uRʝ��ާ�f|/�b��y	��ɞge���������Z�9�8iy}Yn�R��yB�;�
-B3l���
-��~�$/t:}Vj�5��j>j�*Gb������a�9�(�J#n�.u���_�2_��7�g��78h(Ա�o�Nn1VK[��v�� u�q�@\kG�g������8 ��F�C�v]�6lSY� o3�*�3�a�8S���菈�Y���wev|����к�9,�=(C���㞓�)�9ifle �{4�.�S�<|K�!Κ����������]�d���ھo�����zl�V�jW�w��46��^�x$�G�+��qPC��`����;4%"۔yq���&~e�U�7@.p*��U��ɔ�r���Pڋ�_�H�`���\��;˺43��#���k��=G���([�j
-C�)Q��Mh~�}�37�+� GϘ�W�>H؁'׾
-;f9x
-(!�eC�2;��O��if�'�%�S��(R���=�yJ�%�5.P"Q�>�/J�|%\c��D.R�~�"%�g%,V"+aѸ�g�_����gF���g��T��:���`�<%?T�|Ё5M�	?s�{���3	1�ֺS� �2�hB{Y��mB'�q���#(�!�	}�K��%�^m �2	|����5v�_W�0�pd�QPY�(v���
- qA�D=���}J�E"&f�U3�hE�q������1wB4̃V� ��rl���,�Vs�u
-%��1x���I�k���/0m$�
-s�Ǣ��,E*��S�I�s�K�ǿS�p
-Dk�
Pr8 e�U(=�凃P�p���Z���z�I��n�ڄ��>�f�Qx�)<j�
-�����@��@��B��-P��AP���P���yc�+����&ԩ~�y���ʽ��|�{�w!_���6ϧo����>wb�
-~�A`Ir��?��O0����S
-~���(�?����0��~��/)�%�F��ap7tK������տ���-�P�;~O��1���?`�G
-������?ap���`��A���K1x&���`xL/�B�l�=���5��� `�2�����1�
-���lb�"
-^��K(x	/�����^��+(�J^k�����b�!��a���_A�+�Z����á^}%(v ���a�W_��(v
-���-p+�Qp������^���(o��=Ń���<xG0\ǃw�5�d�"�wa�n���� ��c{��0x0,��`���EQp;��v��)�{���ap37c�q
->��'��{�>m�jϲ�|�>k�Z�y;�_��͸\�\��/A�i�`���lbз��1I�f�^�8�O3X/c�+5��+MT��� p��4M�m�����ȇ����>��H&4e�!��?������� �c�3Q�*�
-�Cʠٮ��q���{�� �B�*4u��T�A��w�G~��HOD�4�@��7?�2�#}� �F�^`���}J-�f��"Ec�wa!_ѿ�����*���u7�\��<�f�~)���WB��?��2�W4?hf�ѿŁ߃	OR�����=� �!ޣ��Wd���U;iT�	��Oǟ���H?3?g��2�9�	�ځD���������s����?���;�k\�D�V`Հ��h{.�����y�^L=S���0��@#���~I�
-^�[��mB�-�	��nRZw�}�-{��UJb�W)����˵�j�5��Td--B�(�Z�Q�����][؆�:����kC��o5^�S�� ���v]��?�)0�h�Kʥ��=��~���Ѽ�!z���I?���w!r�R���@ݍxP�z��%�? ���
-� �m�oV�'m8�T�D6r���_�������U
-�aM{�Q���D�6��U���6�Fٿ��r�͸��ps�w%rh���v�c��d�'ԻX�k�b���*c�k���sw��V'��;)�b��yW::i��I��NZ�4@'M�N�"�_ү
-�W��kB���5}EH�6�_ү�+C�@H_�W��B0%�5�y
-���U:5
--؎�8
-��=Ѿ�Ξx*����^Й�v-�vŻ�ҹ|tΒ|!�5��z�x������>@���>����oÆ�7�?��Df0����;5��"��y��{��?�~񪫽gL��S���3~Ŋz{�����􌧿;���ξ��9��=S��}���{�6WGr�p�m������3�?�+!O�Y������<=�������}���5����?�ڄX�!��W����s��8��v���5F��Ƌ7���o^*�0�f���{���w^��ǧ�v�_7AY�k����p��/�-z2���.8G���A7y<�0Ե������Qɾ\�'wԴ�����<���ƃ���Ż��y�<Gy��bk=���!��֭���UM���9�1�ƿ�@	��>w�t��K��t�����Ňv�+6��lY)=��[�5���� `o>8$~���5�l���M��o>(}��m��V�����C;�{/Y=c߃�����/\SsK�>�����e�_/Z)����[��yFҀz��{~1�=���5�5��y�oO��w�Ma飦|il?��=;~�K��}r��}>���9�w&/�����?����o���?1�?�n;���8������4�<����^q��/��f:�y�T6��_"�����d�#M���Lǻ�{�� Z���RNM'q$����=�G���沅�� �ҩl<4���;57��gzr]5�n�*�`^p|���6~�t�{�FOA���ŗ�� (�+�${r醶���bW��	���i��̋'�u%�9�͹lk�I����BJ����/d{��ۦZa�LcUJ/Lw��	�h��6������3��d.�[��)��A5��̦ǩ�|_g�rɭ}�I�kn;��J�S�=݅S���Bn�W�CJ<۝΅����jPH.����%����Sy����\l�u��T_g�5��:.�J�K:����s���Ќt�3���*��7/��JBr=�P�����Nw��Z`�;�вZ����f�ώ�sq}��A�مis`2xPw�� ��0�>J�KmN�׆�[�F��=Vk�ĺS���)��Tǰ�rm�PFw2�`��࿦�$z���X�f�,LSH�n��kα�-�G;��(���N�O�9�6-��M7����`h��J`vO_��樶��e�v�֩�(\�A�֎�<�"N�+�d�������k
-t��Sz� ���S���:�t'9�,�
-"�� �CS��	�4�ت�` ����qh���xX]*�K�*ϡ�*�	����Y�U1�����]n��rSa3u�)��d����B�X,��w����teB:�.GM�Y�ddSs�x(�(�;�w��B�z���d�R=}	Z5�g��(K6�� ��xw�M�@<���S�.\�L��I(�3g��Ļ�Z�!��"ۀ%,n�7&H��!� q0�w���.�R���2���}������S�L�5Ƙ5g�G
-�l�΃�7�s[�
-+�t"���k+o7�K]N�V�E� UeQ;փ�t�F��k���M)9ŧ�6%&~{��U��ь�������-t�Ј�aʦ��dn*�p#ܜK��>`�锓��Z���a"91��NZaD��NM�$b�Z�ާ�@u�i9�*kk�/�u������T���:{�ι=\:W�C���[����v���0��[ڢC�8��L-0E�Ȅ/Ro� l/�	Nѯ�g.-�]ND*�Ϲ^5�
-�l��N>�g��S@�,(��Wo��-E]�%��/��͸��J�1�3�u`5W��̙Q[��FX϶=(	`a�����G:�(\�L!���[4�D<yF�!:l����P/�:qn5��nܹ-a�'��6kg��E����ӑO��i�)4���M���V�:&��k�����Ѽm�KNak� )�8p0^( *�a�
-�o��+�]��t�&i�f4�ﴐ��OB:�Y�ǟӁ��K�H�]�9���ͻCl'a�gv`Ǘ�&����g.�~����^}��Z6�z�<#'9ʷ��J��Z7C}��Y-�Κ�꣕�h�%wq��銥Q
-��T>�d�E��ln��������P�ҟ�SAג} 0B���	6�
-�f��s��\�{��x�6�"yHg�s�Ti�{��b� T6ؽ]��� h�����FYT�D�+!�D<2Z�tmD��?�9r#���5D�u�H�4{-7�VL;�b+Hs�u�aF�?��	���T>�=���r1s��rȒں��ȗ�l|�t�f.�Q�QSz��H�ͱ�e���$�"#�T�X�c�{��æ����%f0fo/�;�j�6c�t�v�Q(隈�^��S�:g���;�9��U��.�Aؚh
-Sa������;��s��xpŔͻ�l^�:�q#���u��V?���VO-���a��E��]�$["v�j�����%EM����eh�V�R��Q��2M���p���4_�}���V"�1�y
-�Fb��nSm�����gN�5C�Y�L�׷����l.:�׳��P�0��;1��[��$����$���W�u ���;�v.�M���u�k+�5JƐ��kS�q��$�G[:t����@nYD�L���I�ܼ�y\�먟�4�>i�mW>dǜڳ(_k�u1�#M9�"�!:_��m+���,R6Id�#�v92� :i%z�	
-�MǑѸ�ձh]uVQ=�
-��e3G���_}iJ2;0�>c��Ic�sq<�]�H����ᠦ����Lg
-���:u	9:�Hv�Lq���f.2�aIoZ.�0����@�vд�cZ��ظ��P�g��^�`�aaRU�)G����\�`��U��کL���Z!z�ޓJK�<)X4��Ͱ7�-���Jވ�z�B] �њ-���I��.AY9��NS;��<F+�7�f듸���d��ЗKφ"H�Hv<y
-�G1�+���T����Z��
-���A����dE�9΅��1v�*���4��4��6�e���`u����M\��^Ogcál��}ݧr���=�� 	ֺP������<9`A��<AH�8zqWq>��6cIw�+��.a��+�����U���1�'�IB�rF�y�
-���l���	*w�a/l��2:A�� ��1�Z�Qu���Z�|_���VƜbI�j[��������
-ov�IPU4�mrX�Z+�J��IZU�x.]�mO 6Ql}�)Ö	�yy��Ld�Nm��P'��C\�áO��z�[�2��Y��a#��'HX�I�:����Ш2N�Ս��Lpe'�j�V^7�;ŗ�� !1t�"�/L��)���m*ݍ��l!]�����O���"@+�>��8x>ibl�q*�pKMU�y3y;ӓX
-�J��#�@������[y�[2���-3
-����8�˝�M[2�6_�;N�����; �za/�v\� $��k�=�sz�e0*��0$�L7Td:aqo3���GkS�S�H�;M"C��I�����3�P;�}�F��:��x���2ؒ�K[��|�6Gu�*Z�8�C�G`F�h9�[�E9��.����UGmd
-hR�u`5*3��d�]��R��%W�HK�Ћ����*2Uk�$�Ssx���
-ܗL���F��w5ji>��>������Øw��M4y��9��\.J�kvL���b@���R�z�sS���0F����[�M-��nv�E�M�ȟ��eUU���3��E)��ht"K4m;F���dF���e�j�]��S�s�D�"+.h��X��5�Ex�F�EnYkF���K��]wYaL�s�,�S6��UZ�`�Zx��Eٽg�iK�Rf�fpv��l[j���l��(��k?o���2�/W� p~ϖ�Mb�i��;�K@���\9J�F,�Uof���l:Bܚ���r�i竃|����JV�n�KQ6D!��ר�#D�&jK�����!J�T��Sd���6�Hc�W��f�X�`�1�@�#��,��������66i?�r'�����k`Sa$�Re�{�vM�L'5����DV�փkp�ܵϭ>4]��X�n���4�?�g`G�.L��tuM��4�%{-{��6�7���H�p�0+�dk-$V#l�7��9g��9�`r�`2��19s�S�=A�}���_�'xN�:����r�*ϧ�>�J��\~��\R�5E��c�l��6�,��f2��}4����Z��bb)TAT,���RԇnF��(��ǅf����5��/̇w�
-"�4Ε��� ~�-�q�F�ؗP�v*��rȽ��9�7ڼu$��E����L�;^do�J��=���h�$�j):��8�)��d����3r%���bcpYIA��M'͂�?��O(>�/3�ia!���-�Jd�O�ҧ�im7NO���^ers�ԯwIk�rq<����<��P�I�iI4s1#�	���"l$�E/6cNVb��g!��7c�V���n~K���9L�xv�u]�`o�y2�������B2�8�U�e
-Œ��0u�&)��k��j�MsҢr_��
-��N�0mw���q�t+��A跣A|�Rn�
-S��7�����: �:�*���J���#Gc�̭���2�k�T9-D�c�@�FCb�Q���48�r��n��B7�^.K9���P��&�_��#=��&�h��X��BG���BS���Ǩ3EqG��"'彈�F0h~��L������Jo�����.���I�Z�������#��$\hn�j�U���4��b�j�J��D!�Hq�e��.3XT�B�IY׌�����4V��Zya�!�e���B�ј*+�'��.�G�ى�V\��唇�!<'�2��9��2w<�]M��"G(Z �2�s �[��F$�G���L��;M���1���Qr��uS�����P
-,Z=a��We����>��x�LZt�@�vWDm�G�%e���E�T�k�J������m���Տ�����]Ð)���ڵ�u	�(�TZը��a����XiA#�vA$��T��miѥ6U�F�Ӛ
-�[����t���5�S�ia��6.�g�bfa�������֏�؆oURg:<YuKet�pj-sv��$�a���,w������[؊fu[��j�x�OU���
-�����4M*mWq���eϮHFhtџl�_���ž3W�On쒭��\�Ϛ�?�2;��Ƥ9�ѽtH:N]c(Zt+bS������v�)q�,��Ln͍�>����$��J>xV���3!�73"�d�h���*��/T�xE(���8�!gPK)8���$ݘ��	���1�!��'�,,I���� ȻR�Q]���3�*�I2O��
-�J�b��цјdQ�'ҍ޹�%V�4/���iL���
-�"�_d�dW���Hq�?���c�!3�b��<���+��
-��C^ k��w#�UD�	0?F^H3�ѼX?(+k�	Lv���'�1YE0��������Q/��>��;a®HP��*��6:q�/��>q�!G�)���⊏��e�c�c7rV�-u��.��БI[Kc���9��?�����O�x�G�?ehޢU�����B'*���H���*r^�+"�,�o�'��9��
-ʪ��c�c(%����[u�������@���F���FF�ί�h�?&!fcv�k�h<�x�����-���K̰�a�1�� Ɏ������e�rﰕbBϖ6UJ�b�E�W6q퓓�Of"�������~�����{��/�I�X����=��-�D��Ř��Qj���"�&�ǯ4_�*�3'7(*�y>ʾ/�t+Ȗc�8��n9��(?�D�������?�>|�V�z�[�lbT��13��Fg)���Ngu��p���9qTP*�**����+�j%E���I�����V�*���dA���=����.��144����/���������ʧ�|v�TMj=Z���
-�0��P�cw�M�F_�iv�)7;')�Y�M�q秩����ml`)(��6U���TOGt�g~ֲP�	~D[�qOk��$X�E���XD�&��s3C��6
-���TZn���ƍ퍲s�>�n����=Ч�C�������ٍ��e��-�e%m*
-��@Ü�&F�͛�6�l��0+3Ó����� 3';D_�.�Y���Y�|�ML����a�ƍ#��UԦ�$d�ۻ��No�c��͙x.c��m�6�LT_Yy�K�f\��.�M3ߵ`�f�A�o^�{y�sj��m�q�%�2+O���2C�mؼi*%Ҟ���_H����twK;���T��B[L����Ond���h
-����H"�xj�VP��ȮuB�h��9���*2Vb��v��\� .)i�T@��x���V���ɑ��g���g'�ҏ��񅼛����.�O��X��Ъ�5��Y�Yj��g�Fߋ1�BL6��H�1�ր�WcM���"��ir��*+�G�Rg�ޡڼY�("�n��c>T�A7.����糖&w�����D� t����Ka[�X�1��x޻��M���+�)���쨈�v8������Yk#���$3#�yK��wmb��qF^_l����bW��~d�9Mg����!&��
-��浨LN1�g��s92���Ĝc���jF.�q�ǆ�@�qd.�1��qMk������5���
-�b.O~2V\�feW���h��YE�����v�0Fjj�i.=��H-���j]�3]c���x��n�H�dD�]��j�
-c�j�S�_���,K�T��i�h ��g�|-HC��а�-꾥�p�@]ܿDG(�"���-ä�U���r�E�ڢ<1�&c
-�{�螣"|b��F.����w�Qޕ^��PH.�K��J������R�0}q����ltu�9}�5��o�"����T���Ua����H���>.kY,��Y��<i{����ΚS&F�rڊ�
-|����D}t~Vn@�H�4���O֦4L]����9�
-��'�Oc%W�z��*/�p𘗞vMv��;P�ݥv6�NG��IG�nUq���J�	;[�Xl�o�̦�CYy�MBr��������OZ׳��M��\�K��6�������*�]BSX`%�U��I��H��v��H��Z��~� _X~�Z����6�r��KZ��r
-�\Z?kU�ɉm����0e�
-K>)��P;�_~��X��x��+G�:u�(�����/J��8#z�:�24�yjHւ	�JT�¾:�odIW�`�D�R��P�)�!f�VUWT�8�m���I��ⓎO։��%X�G�vq��:�{Z)m+-�E�s���%��~#��ܦ��F^'�N��OV���[���/I����b�w˶�Kڔ'���ܠU*�K6�}V�
-d��P���� s�[H�4B�M�D*�T�IH���̺��k?Q%!��v�7
-�C�'&���	�}:Z+��
-���o͋��+�S"!��|�QU�޿؜�C`��}�GEIjEyj����R�Y�ӫ�x@dC����6q�I�*��̳L�k���'���UD����(m�u�79��)��g|�����[Y�*����33ln��k)�M�'�
-'x��248�6{t��+n
-U��by�Ic����0�SXV�s�FJC믳@tY[��b��\G�L�YI��/�z�����I�=�(����W<��}\X�:�w�)y���_���NE���
-��Z�|S�_�u�S[�b[ɽA���0��Ĩ%�)	�C����s�MF!���7~Ƃi�э%J�:��䗷�|\�69���-�9�ܑ�*H/�0��U
-
-KŪ�ؼ�ȳ7B̈́��X����8D�#�G��P:�v��+6+��Vx#u�<�jeA]��}��S~����/��t����u������U�j�n���!-a޷��%��w !P3�D %��s�Z��u�~h�
-�%��j�jJ���}��Q�c�~RѿW��J���?P�v��F���
-S�����V��a�gق�lp]8i�&�
-�w{�8�
-�w�u�#�UW��+x��� �\��`ow���a��H2g�����\b������b�W3gKп�&wU�/y���&_�&_�&_�&_�&���^��Wo��;��N>��O���{���>}�O��ӧ���>}�/p�8��O��)~[�d*���l�}d��]���<���������@��d*��rC7�qKw�qW���@��H?H�
-t���;H��4:I��4�H��4�I��4zH��4zI��4�P��_�gɣ���	z�DXj%o�>NèY7y1��z2}��@j6H��jΰ%�ғ���Ě5�#��c��M�~5QD���\�0���K�Trkf%S٭9ő<ݑ|=)�Fl���ɳ��D�'S�M�����$�x*��TF�O:��T&S�L�R	c�]��]ɇ`����p�����-3 F�Hw2��?���\%or(��]a�SyVyByY�()^��Zi�u���0u�:B�~��R�TG����i�6O%ח櫕�����R]���ժ�	u�4u���j}<��RU]���媲B�ԕ��\��Vg���>W֨I��ת��ש�e�_m �Fu���z3Y��[��7�Ⱥ]�!��v�u��[Z�5Y��{����Ⱥ_= �o$�!�����Y�Q�J럎���zBZ�O���zZZ�!kwU=+����z^� ]~����~'��+�Է.������G�+d��^�֬�d��ޔ�?�"�m�����.Y������>TIk���Xmg֦�-�~n� ������YZ�u!kWK7i}�;Y{XzJkN/Xy�������j�kQ�Y��-C�wXB���=�4�:�2¿%�?��,�}����!�9J�T�H��|<�"J���KMS=�/!+-ea�e罹�U�XԤ���K�%��+i���2�2~'X�`��[��Pԗ�a�2�2��j��J�
-�8e:�j�gY�	�Pu�%a�e����<�DEM�o���o
-~u��ZhY��*�꘦�K,��p�S�e"�{&��P��LW�C�²Ҳ�b$r���V<�Uu��ڲ�s���u�X?��^��S6Tr�.@��-�Pu�����o���ق�z���Rك{��n�H��ʶ87Euo��;�����t
-��(����
-���O���»�6�c�+��h����b�B�aj���Ke/�V�jV���a�9�A0C����9�G�D�j���/����5�Za~	�h`�ca���S��D>�`N&�<�:qN��>��3�,���9�\`d��BĽ���`)��`~,�񬄹
-~WC��������}-�����7��&�an�����6`;�w ;��
-���Ӂ��f��
-n�a�ւ_�6��a7!�Ͱo�_8eVk���N�������"�>`?����!�G�8�����'�����~q���Y���j���Eؿ	���y�+0�¼\n 7�~�m��Ϋu���~�< B����ǔ��vV�4q��('@'�3�]�,�+�
-[Y�%�R+{	%*mB�UR��}9~}�V� _
-~�n�`����yOq�a��К�߀?
-����	�$p
-��w�Y������EJ+҉R��wV�\���!��+�¼Fo�
-��ᐍ F�G���G_�}����ڧ��c!?��O ?�$��aN�9~QjҦ�>��^�icufsl(I6>Ӧ�d��+�m��&��+�� �~�Z���0���W�r`��U �����
-����l�U����&��f�[ �Sw+�l��@|uw �S�	���6���׈iQ��m/�}p�-۫T��� ���#�7pGz���
-�Sau��<�	{�����,p���8��o��࿃y	��0/W����_�7���-�6p������#��1�NC�|t :���@�+�
-�+�U�j`
-�'��{Jc���������-�4\�.���� �Q��\���� i.�
- �Hk�5 �֮k��Ưk
-+���"4�E����� �G� �ߢ�0�1V��� �u��	����(u��tz =�^@o���� ��"tf���j���F #��/`��Y�R�(�_��1�X`0�@�hL`�&`�R4�`*��Ҁ℆[Eí�`��b��f� ��B`CÊ�`	c%蔩Ka_|�匹W��;RW�\�cL[�X:Ze��ik��-�9�2��m�y�3�	�n�k����ǘ� c�� � G�c ��ώ�<�d��i��R���va/ !�D�.WK�
-�u��+��܆�R��>����Dc�^yD�~ �H;�=��u�ց����;��fcѮ�t#��:�\�	[/��&�>����~@8
-����c(�����8"4�4�	�D`0����*q�FӦ�'��dE3����f#��3��̦-�e\K�u�K!\,V ��H���k����FQ���l"f3�-�6`;ŏ��������.��"[M�
-W������� ����C��ǁ�p
-�ib0������p�b�@�["E�!;�#���p�$W�v
-[�����������R�9N���DN��i[-�⬃�!n�r��-��D�ó~�`��D��v�\n8��mPn�r���`���oR:@[@���D�9A���H"�t"ҙH"]�l��.�fe��Xw'�ʶ*�, =��9QН�����#*��П� "�4N����$�P`Y����6�,#�|��)M�f{r
-0^R�i�26<�ځ,3�<���K�s.ǐr����;�{��mW��߮,&n�����Ne��pr����T��T�-Ӗ;�e���u%��T��T��T��T��T�:U��v(�B1U��U𽜘�`0hU1�T1�L[�p-�+(�(��#��� 1��zr��D��X6QR6��b���l'���	�"��l$f7�M�|M��q2�^'ۥ�� 1��s��v�� � G�c�q�����o���s��S`0bM;
-̩�c��̀t&Yf��M�K��b�y.vLYHd��.v�Z�c���!���2�򕋽��t��&N*�a[�bl���V6A_�mt�3�f"[\̾�����9�\P�m�B��.���Ŵ�.f���*��N�M
-K��f��~n����*�Fu�@��u(��;��ک_E�K"���!2��8"�L 2��$"��L!2�~��:���t7�\�Ed��%�q��I�d7��ï�&f���� �E�b`	�X|� V�ܬ��������z`����M݌gB5�M���I���m#�^w ;ɲ��n"_ك�{ᶏ,�� r��!����"Ga;�f��#�	�$p
-8
-�p8	���o���+�5�p�� ��v^t���@g�+�
-X
-r|��h��u���p��g�$���l�:Տ����P�/ g�����(��t������Au��ϥ2r܂��Wz %|�����B`�X�Oq��V����U��#����+����r�"�J���H��Ld�n���������t�����n�k?�WR�|�Ma���� ��?���>~���,~A�@p؏�w~���玒��*ߠx�f���O '��>4<g�s��U��/�G����E�;����D�u����������^�g�J����
-�6Y��X�����}�މyQ漼}�eƋr��#av��#��@�^���{���s�����H@P�^	l�ڛH��7�����(�0;1*�~DJ���@6�~P��M��D�K��D�K�C��D�X	�� c��$�K��$�M���=�� ?�%� qׄ���Wq�D� ��c�5��Ü �?�$�#�
-s0�tbA>�,`60~�Gn�W��ρ� �"`(��0�!��#����R`�0ht�[`9�@𳁕�G�\s5���k�KZ���9�M� � �'��0W��s�� �1��[�>p{z~�}�Ѱτ��/����	�a2Ғ�|H��@�Y
-¤�R��<{
-�7��Ox� ������<#=)?C�:�42�i���Y*"JE&�"�T�ԑ�Rᖊ�����p��Y�y~���g��Y<����,~����s�}�s���9�y��a�!�sȐ�q�!�yn��[	/�A^���2_���/ �/�p���_@y��Ix�^�wanƀo篅8i<II�>��	�x~�O���
-�	�
-��,`����ur~n�A����0����Ŗ���Sr���׾B�zЩ�+���ȅG�Y����l�!_��D�"���>��y)��?�W=������l�ക����6���	��wށe'Iv�?��~��~��ߤ�˗���_K�e�r��W����\V���ͷ���?e�k�����k���ׅ�YcEM��i�}~Qy��G��:E��Q �z���>?o��S��\
-?�z��s}�/����7~:�7翡������p�y��+�_���.�M��)�7�G3��`�����l2�c�L�.&��-x$B��-��bM����N	�^�l����|��O>��&X��w�O|ʗ|1�!�l�'��g�?�dp� �e�'��?��2�m�sܿ��zJ>*�|d>���ǘ;�?v�Hi��[���d֒���7��)�
-��ZTk
-/E�=\b����-Ɵ�vy8��U�}�K�x��@���=�c7珌C�����S�$�+N<Q��:�_u޷���W;����^�ng����o�"C�G����l���TBʃ��\�{j\L�q
-CT������X�{��F����[��������z��9#�^��R0ɑ�M
-t�
-�����������O7�J���G���O��7��`���Pw@قZ��V�u�6�5�vr6�l�U�N�T�𔲛G��{P��e�Rؠ�R�P��K3Sԣ��
-�
-�"ʹvi6W��U��]��}���چ◔(XϹqU�����[�d�M��C3V�=G�|�Ҏ�O��h�g��T�~�"��X�����P`�Bc4Q�$Ұ�_Q�*d@��̇N�nW��# W�W��3�7)Y���>Z��e���UFC�Z�<K�Q��*Q�f� '�\)9�MJ�"\�iW&^T��q��IȍW`�h^��+�uELQ�6Ð���4>�C��
-<�OC�Q�|>x
-H��A�+�����tUY�YY0�@���i��p��^��!H*e#6�U(R6�R6�-h�e+H�6�O��Z�w��+�.0�kw�pO�T+t�SٛJ-�~�} �v�"W��+�Z@
-���A�eG �Ri���i�r0_�F�u��Bߤ����8��q�c�	�7�~2p�S���iT�I�r��C�l=?/;�I���ۋ�^S�BE���rYr��/UZ��F+
-\2����*4S�An�r�d��pC6�&�[��w"�U~�^���U���; ��E�=|������i�g*C��"Թ���y�"p�2<���y��x!�{X�^dX�ܑȝUFA��
-��C�YRh6��)%Bΰ90n<����jb���� �)!w���|�f+P�mL/���2�m
-p��,�kmւҨ�\��G�Ky���7�rB�y#
-��U�+6�qT�0�:�l鸲-h�(i��aa�����FY%\�	�;A٥�
-aw�쑶V�3DԠ���x�R�rw�^h��ԃr���?4 �� �(�۔�1�Ҿ�A�D�*���9��\�:";y.8��Qxl?��-�qT�ݮ�*~�1~�*���4�3�3!���zh?ࠗ���l��7���b��� ]��,C�^�/�>C�,Ǫ��[��ϛq�)�-���Z���у�U�b����Zr�󇯃6KiC���
-��3A�� ��#Yȕb�����Q���8��R��J���Cd��L14-G�EX�
-��O��F��1j�:V����J>��E�*;oT�T'�}�-�|�:	�� p��L���l-#�ai�T�^LEa��iԠ�(m���ң�l��"Q�Ҹ��Z̀�61
-�b
-�n3U:��w�ȁ�;b6�#��WĜ���Ȥ����<��s
-D��a�u`�Z�>:#�G[���E�OS�Q��8����r�6�%��I,~Z���P�D]�j��
-h���
-ЊՕ���*�q��@����b�4f
-UO�_��3�LU��RρrS�#��Pi�.�K�YJ�h����du#4����\).~��S�2�A��e���b-�,u�����c�+A7�{�z�_ׂ�\�چ�č@�B�Vq����[�OWo��B�Cߜ���k,[�}�7[���H�=�{r�;d���d
-�Qj-Jl#B���¦�73������!9go��
-1*�u��5;p�C}������B�#Ա�6.��� j�$r��#�_��qs�,(��Ah���]8��j~HF���]P;���a��d�ǨS�ﵯVթ(Y�NCsW��@Aw���7�O��u�CE �W�e�g �a>>�6���{�Z�
-�8&���"D�J4���J��~^�1>��`��Q�㬶G]ص
-n�J�~B��Ϊ�Sw�N𯪻 /���?��<�nBC��ՠ_PC�i���Z�%�Vz�a�/V�:�ܠ.A���^�,�}�n�^�4@�quJ5��eg�eujcP�A$ϱC��C�H�<d|��U��b��;�t�L��b'B�!�IP��N���Q䆇�g��S�5�L�L
-;b@^E�Y����s!6�7إ�uX��4z��F�
-�Z�FWR�5�i����?d�5-O#�� �%�/�X�+�&I��$�G�TSdn2��Ӧh�e4��kSa�[l��N��B	�k4C�$����߰�Z�X���t�[�͔�Y0x�6p�V")�Uhs��\�Wj�������
-�n$�i�4
-���B<������|����(pZ+������`��E�����C+ܨ-�����_[
-�3�2��BF�*m9�MZ�n��$C)��j+��j+��@^�zm(��j�]��9��൵�j� OB�`{����k �i��l�6?�U�6�f�U��C�����F�+X���$��X��l���"��mF�m֪A�c�=����IF2�����?wŇ����
-���sxxt����g�k G�k��u����xV�pD�p(�uh�����d*�(lp���$�]��Tߘ�Aͱ�c�a�	T�"��!���D >|j�(ԕ���R>���	P��+ش�I��S�g�O�;)|����'������f�σ^
-�nwn�
-(���t���Mk�� 
-_mu��kt׻��x��?kC�l��I�I�P�EC�A6귁	�^��~*|�|������
-�E�ѨW���q�c�\Л��/�L�p��p:�����&X[x"dZ�����'A�`� ������d���]���)�w��B&]�� ll�^�Nx:���"�{�Š�C+�� }���J8�^x&(9�,��ó���%���s��E`z�����s����>B��ڋ	�~��-U�8}�,}>���.�գՂ]F{v"� ��p�[h΅�Bh������r�*�lx1�Yz9��Ma��%���P��O�Ԅ烲-��i�2P��@9^8��� �חD��T
-��5��ͨg��E
-o
-_��1���c��M60��7����}��-�eȵk��QT��p�����	T�Pa��I���S��KAQ�"��l�q܅�9�K���Eae�Ĳc�߆��J��*��$�wl�!����E9>�$��~ϪL�$��C���:��*���#DٝF��+����)���:
-��o����t��a����F*��k7�A�N��C�Ͱ<�ܢ)m�S wG»��F;�{a�UDlF�N!�`3���ri�5�RSY��Ҹ�(����6\��`� <nd�6� �t�qиE��	J�1\���b�:"�$�t����c�㐹h�B�
-1������q�5& bN��Y#x�1	�1� �ɘxʘz�9�uc�UhS�e�n���k�1������8�uɘ�Kw�E	�®%`��sdG�>�,%\�n·����^0� o�������\��Hêa�G�O���bȏ1��,�,%�\���(3���B�/i���P����P��D)1IJO�ry�Rݱ�9�b�ez�1��B3�\Z���nA\�B�-�͕(����d�t�JL�6�6� ���e���Rs=�|sZ2�܀v.0+QC&�O3�Q'���Z7�u��&y�B
-��LbR%c�>Y�lI�b�ՍBD5��-���Xn��п�B�E�t��V`�Ul`M�f _ k�5�|�G�Q�e�Rf��͖��Q����zw.�ۥ���<���|�Vk�U��p���J��K����Z
-x�Zx�Zn��T ?o� �b��g�l��	�fk5�����Z�k�k=�5k������tCT!s��x���jo<nm5�W�m~��n�Nh|���!�.�[�����m�7{@�nU�Y5ҧj�o��d�е�9k/({�zَ�5�>���~�Z� �&���:x�:����C��+� [��}�x�j�8`�u �Oo��Zu�u
-�1�4�Y댬�,��9���y��V�.��P�"�º�ú,��u�����&�%��`p���f���*몴�(ۭ��ڀ�n ��nޱnt�z�	��!�.to������=����5���ƺ�J+�����x�J3�^Ϥ�:���.����`9v:�3�a�#��l{8`�=���41#���� ��Gζ�M��f� N�� N��{���G�� �\��o���2ٞ 8֞h�xa���'��o ��Y
-cO6�
-{B[��>{�	{5�{�융(��^�{�)�m�W��p.�U0l��	j�ۛ6B
-T�RX�
-�Ծ	J�Mw��-9n����]譶۩��&�g�7��C �jѫ΃�#� X�4���P�Cv�%�C悝d�[�>�%�d2-�d&���	�����M��&? K7ۣ)w��_�j1�&I��L�%�U{
-�:c��� Ӝ\���x�;v�Xg�g"�'ߢs�$�mv`�3ْ�d:쩀��4��N!�]{:�-�0�)�ufX2Z��8�/��X8��%��9A2ג�W
-�LGƌ�<����2c��@�Bd�:�,Zs�RK�i��s�A����Q!eW��VY�|-_�\�W[���m�rg
-CE��!P���t�@u�sx�sL�:nQ�ª��eX���	v�9i�C�S?���>�包0�خ�(��:�d%�!y�i���?�\��/�i|Yқi�:-4�V����&�*`�s
-$|	}p*��d4�hd
-���62���4�
-����t��E0
-�b�#Pl��	�,�n6G:��𨠆lGZ3Rk�ѐ��� 6�c ��c�c=*U�&w��/��x����N ��Nt������4�*����Nv����.4+�;5(1
-�,���C�'Z=O�2�;8�;
-oHDa˽���c4"B�z
-|��%U�����FE�$[fFK��M6&�����q��+�����	�n����u�D����z}���ʱa��ؽ���X <� u��9�	�Fp���I��z�<N�5�tI)���ZoF�1����!��ê��Y(~ܛ)�'8;�!JC�<u.,:�����������-�2Z�������Ӝ]���H�q�LO,��kC�yãK��^�c�����T��bٟ��'>�� ������z岃�H���#d��-�Mؚ}N/&
-������O�ғ�.�M�O�e��w��#|��쪿�g}�6c�OO�&���5�OO�6���0�>��U�WG��-��l�_�Ӻ�I>}G6ί�=T'!�w���%o0�@���}����gG�|
-���0����ۇr�>t�����|:-����o@�Um_��.�|��֧Gt�|��٧CC��?0� Z��o<�ӱ~�-����+B���]�ǧ��j�>���O��>}1ҧ���G��E>$6��'Vt�9�
-�5ѩ��Z���ceTƔ81�:}���
-$�G����My7ɸ�]1��pc/m��t'�F���g���s��K�DH:G�A��J�bT�+Z���D7�
-�1���=UW�r$�ڥ]}
-x6�͕_[lwi�� �Bt�+W�]Ȝ��<����M��Ǆ���	�X�bE��� ^MM�I�?GP=����XF=���7�ڢ�N�'[��oDH��%���2s(���]�v��Y�QPnE�I���@�d�2ߋ��ԝ�i��Q��;�g)r���Y��4�>Ͼ���%�&{��#�9�%�w�ˬ^8C0��Eخ)^D\t5
-�(43@f��ȼPY�,
--	�e��*�6@և6Ȧ�� �� {B��7�/��à�b�=:Џ��ȉ�� 9j
-���� i
->�j�v㬱� �E^��
-��a�@���8*S���:���s�R��\��M�#��*�$c����۩o�����";ɯ�z����.}��l�+��C[����v=��ݡo��B�a;)i�>����}"�u��v�I�zNr+��vT[�^���&�����v�^�ǌ���ު�c^bպ��'Q�p^�����x�&�#��L�01�-S��$����Y�]�Y��ѩ�+�4�w��B���A�Oly�����[8���Tc��BN��vM������*��;�Ɩx�uK����
-'ޤ5	t�_�G���پ/���	�hI�y�S�(x$��JT5F
-�&xi6,��fGؘDnB���7V����FfDXiBhQݖ@wFؙ��P��S\��B�K�ȍ�ǣ{�y�����w��N�}u�{8��'�x��}�B�vuz���^7�I��-MH�I��<��{__ߓĚU ��{�}_;�M���!/Ɯ���Fol>����D�3��+^��[������	�"�|U��p$c�Ư{�p-���3�M�E�,*w�M�
-7.!Q8�*Z��z��o'�vxj)����y�ݞ`ͧҵ&�>k�ᡐ�Cb���(�j��>��"����,��p�6?TL���r�?V�� ��������D=w�਺T��2t�h��]���eF��ޠ0�K��݆� Z=?a��2e	�<�n��+ȴ���XI&6x|5a�Ƿ$���j꒰XC]"�u�E�
-}We�r	�?}[e?�����~>��S�������-�V~��_� �����*������������u�Ϳ��ߌw�T��
-���T����V:|��ms�.���v���u��5H�p��'��w���"��!�i�����d0�u���3���4����P>9�3����d��_QY_�_V�p�5����wD��T��OG�K*��"�e����]>���@��\D�@F�C.Ue9��ˋ��ላg� ����q��nG�|��ԁ���S�x��㯫l�f�M�M�Y��GT��w{|�I��=xE?���LF��gF�� ��A��Й�2��bOR������8
-c$݀܆}�u$��x���S`o�m���A;|��M�����k��C�c���|�
-�C�5ZA�U~�R�*���>�d)���F��P���(Vu�Ub`��h�x��\P��a1p����O�K�\#1p��T�`�_����j`
-�G?sN+�ēN+��c���$?3���3|�魿�)h$�E
-zCA#�ԇ��R�]J�!V�����+(e�T��Ii%������ߤD
-�
-Z
-Z�+�E�0�,���ɴ���ŷ�G�5IL2�)#Է��Y�ﳔ�$���<���O���@�Z�	��Ǔ��DM�j���Qol�ņ�q�hpFt���6 Mi�1�����6��bCf܆��Y���٠I٭�j���w�32�g�׳'�Hʞ��';�� ��h�~�-�Vj03H$G��kp�h��|B��f�Y,�~��9QC���q�O'v�OȎ1��G�<5���}��Ŧ�	g�$��q%dZ�4P�m���=3Eu�q�<E����W��|�	�w���l�+����c����;��WN�<�oFj��充���ּ�)*E]��S�Ç::Pqn�3�R�㥝O�Ҋǉ�)�D�vO�bw���e�����J��~��Y?���&�Y�c��Bȉ\!R�`"W�T�N���ȫ�����ީo����sRz�i�W�YO�Y��a�H~+#�-j�M�z&�K��8�+Ժ��wt�����dBI5�BU��������M�ou)����~h���[=�th%��]H㴮�m�	�2��E���W���.W���=N����0�7+�E���Uxf�(���+�/�>�@�u���Fm�$?W����5K��j����XC�k5��h����#�H��e�#��Qp6gH^���!����4���~�+����	5�;:zC�ܸ�G`�2�4ބzj�<�U�������ީ�b�<�/�:����5�T�&:U���=�<f�b�,� [���&�</J��u^��xF�u������v�_�J����WJT���f�n��=O3/��T\G%�]�I�IT�+f����k;��k���:�n)"�RѨ���>�
-U$Q����n�KTcx�ix��GIb��~��lM|z ��O>�
-���..q�$��%NB�$I��%
-��9{^�� �{�
-D"L�Cﾄm4M�����=�-��L7%U� �䢁��'�+Rm���^7Re�PS~,N��O�=ص�M/|����J����<��r�ò�G�¥A�X���#%�_CÑ���X�@RJ���]5����6h�"5�kh�E�@R�hď�{��{B��_��NQ )GD�p�>�����'��I����b )���]��+>K�����)�r�OS��E�ٸ�Jr�sqŕ�~�R��I�'vQ|>��.)n��ߑ�<�@zn��Ԩ��x���=?O�R�x�e�U���41KPq���S����V�ѥ�K�Rŗe�_�<5���S�i�A��ݘ�Ei3P�Q:�
-����%���J�:PY���\)�P󦏓R��ҁ�5�n�{h&\��{��5ņ��:է~4(�Q���t$�J�x*�FYõx
-퇱�� ��~Jq�+:�S�ߑ���#�m�yz}�3��+�|����~I��kj���C��q:L>��ޢ�=�Oɬl�-Q=�B�������I1bS���#^����*"ؽ������@R
-E�hE�xӣ^<9�^���qz��LQt�0��'��M��^F��(�o�&U���yF$��<'�wVe�Y��aI�]MU��ժ)�(�2�Z��퉸�DVE��Tu�fzz��0y����f&�A_��P@�D��
-����Q�Y���8�dB���?�؏��^{��^k���Q�sQ��/�,���b����QWw1)@ؓd�UT�Kr�K%9W���C�/J�:�}������7�Rn�^�s����!H.�+���s��{���S�d�㐊��'�<Ϊ.�!Vu�U�C�cS����^���Pc}�@����cL�g��/��/Də\�P	|�1�.ȶ������l��6*�
-n�P�l�Uj�/�`ap��m���[)q�,%$'A�>y�JWh�����N4�_p�.|�h�d]��h^5�f���h�)ܱ�7��el�7Ҫ��C)4���B��#ܗ
-���H��rL��9)���*�� H(�)۹أ��S��
-�t�#%����`(`bs2�HƎ�W�ĚfP��rf��$���I �Y(P-�O1����@ �J9Vo�U#:\�e{�N�7,e��x	��/�ޣ���Cr�߮a�~��+Y�%W�t9F��5�(y����:�;ֵ����+�r�։_+��������o��|4$�P�;�\Qfyx<s6��"!1=Jh�2� 59�p��)1�Q�U^�M-������d��2�]�)�^��f>��J�_(��G�
-xXsT�-C[#.�se?�c\�A�8�_����
-.3�!��|�ayBv�&���x���!�E�k�ڷP7��D��l��~3~��ݴ_r�(��J�x�%\r��1o{u7P�
-ڥ�bAW`�|!ſ \q�C�����������R2$&�~�v��0����$���r=/��`���A���.�&�y�k؄����i>��.?���p�Q'���1��\�*���S�g��"�o��7Rh\or��I�����ġ�-�K3�ϸf���HNa�3��X`H�Ie��{La���!���2.��#�8ā�⠎b�0Z���U�nCN�!�m�:ng��7t�Nv��qC�8��QH,�=b���pc�>"'��X)��R��(����lm����YY_dH4�%Ne(����Ș���Tܞw�ڼ�xBF�Sw�GN͐q�ޝ�!�Sejfdv�\�(ڻ���lm�1����/�C}g$���g$d)e�(FG���
-��Q�)%աXv(��&��!61�%�d�Vz�ԱX�c��ŘĿ�_�!�8�]�V��}�9�� �J|��Wj��0]MLW1��ʲ>�r��I%F��W9�i�ㇸ��~Wh����/��� m�vJK�QC�,��Z���`�rB���i�iS�*��r� \��"U�ڣ�b�='+��{�~�u�׵�׵i���im9cJsK��̉?��[%��w%��6��nDK�͒y]�N�iuq�����V���Ws�?U�O���8���: [d���rb��}�����u��󠿕����%z �ȫ<�H��(� j�`�QJt :���N)4��݁v���@���`���Q�~R�O��~�$�ɉi2ˉ��C�d�=V�>�r�(㲧��i%�B"�'�9�+������i��^�]*��)����#ny��/SZz�k��:4
-�ZO�fcZ$�Zz�Ǉ���"��F�KE�K��n�Cc
-�e��eT3��x�<����c�EI��S�2��y��~�^�qѳ���u�D��z����9���m���~�����E�D���y#�H��FZҴ���+�m�k>#�>W�>G�4�
-�u�r�q�N�0�"0U@�O���d��#���C?�8a���$���}!�~?�_BN�ND�~?$���0n�Z�E2JPQIt��k%�;8���YlП%������@��r#�QO�f�J�х)iB0]�x�j���� �YԼN��O�~+:��j����JC��LZ�MԋhZ#�f�{\[���NW'&�:nέ�/Uˬ2��j�y�1Ľ�+��FVRwr�#iJ�⛸�h�bʧ�VRO��b��!�����ΐ@Q4E�Q4���)�QBUb-�ۯ�bL�G��;03i�	�r�YKFa�]�i�
-������׹޻Q/����޳�,'������g�\N����ZG�:�j���,�=�i�Y�@� ���ț��d�D�]����QV�sh���s.�Y,���X2Z�3qS؁���Jk�7GAs�S�TV(���u~z��/�v��~�
-��+�a�ܦA\�àK�wɡ��GM�!�*�Ӆn\����w��t7I$�A�}L�l&`�
-Lg4�L5.q�k�\
-2����*-ٹ������B����3:���C��#�?��w�����
-k�?��/%k��@�s-b�jɑ���f|���}���/�v��ǔv�Ǘ俬H��>xT܏U����K��H��0�4��ԭ�zfvt�N]t�ۻ�"�7�\��K��,���q��a	>C�⫡��]Ht)r���~)�F��[��V�o�_�\�Yv����w8���mZh�U�RG'K���̢���5sNb��fZ���Q���(i/���t�{��>-���G@!��.���UM;n}�
-��ED�Q.Z�6ϭ�nH���4pk8D�'v���
-�S1�u4�DA�d��G6�B�S�-b�Q��B��X��to�p�Q"��_���5b!|�p���|bjT��*��|#�_G���N�)!��Ĥ>�
-��UR��u�M�0�qf�'٤�7)���!Z�1  ]��8�-���yCF�t����H�uf�9��m�!�5�<0���q(��%#��R��V^Ƥҏ_��t8W��ONf�Z�j�)Jc�=�����*��#j�f�`�j���U�h��O�G�A��F>��f�?�.Nn2IR���,��{�P��:��@0�{-s���T�vWh�$D2}F��p[�
-�Yg�U�i+��������g�Y�3�r�Q~e�
-�Z����l���G8�&c�K�d/��oxY��\Z�#;@"���t����!֟������j=?�N�=�h�Ѧ��7��F��hq�G�w7��)�k�F~}��4�Hui�0Yú���0�W��gV�������%ѩ��Trս�[�k��J%9-��~��xbm�i�oP�n�j,[V��z���c�x��PiW�CXq�9�x�
-*
-���~
-���Z5��z�<�K���#GO��#�+��:Ea�Ov�����3�K㻙XP�N�7y!��&O��vA��"�W�`��\H<)K-c.Y�cP���Od���G\�0�8��4�N�B���p^�Q'w�|�a�p
-����yJ��ש;�Ѡ��9f���ſ�ͷ/ٚ|]��.�
-c[e�Y���7��N�IF�}�bO(�Ϝ6\�7
-���}�p
-�9Q�k��F��5bө�y0��О��`�Eh�i�krn�iOiSL{�H�f�[j9m�{�j�!�g��r�C�L{��6�%"t�i?���thmB{�����j���غi<w���\�LQA�}��p�Z)�kdH�����]�6��_:�-*�+<u��Nl�X,|��l��}T�U�ˬ�n�昙��D���+��y��%]0��/��	�l��] ��KɑcG���%ʈu���0Z�#Jr�L!�<��Jr�����
-��~���`�ř�=&����B�Y�.���I.�G�g�IH%�|�Q#�ؾӺ339��Je�ީ�Ƨ_�ec5�KP9t�xz!G46�)�"3y}sh�����������N�84<��&I���
-x�)f�J��1�#�i��g6����
-OE`*�`$z�v�0ڨ�/Z�k�ʑrW��j�HG"�*�)�?��-X��� �R��q©�e�0���d8!SYu�Gk.�O|ATEW���x��-�Dn[�R�}-�Z�:U�E0v�B��&t�����5�]Bb.b�r��z���Ocp�^���pY9%(�uC���z*��/\Q�NvK�7aؚC��10��yg�*��W�5x~w�P~4+�t�;������~�����0������Df�㏘���6`�z޻��_���yANQ���"	2z��{u�Ο%x���l�����(�!l4[�|���@�L�H�|�<:dd�+A&��ǌ�{uɭ�O��?I��������s���m�J�����f����{��"3$��	
-�8����Ԧ����
-��}���5k׬B{T�[V߈��9�������~��V1��@d�g�"/��3�?#A��Fj"�[+%5e��zyמ�(�4��B��ó�=^��8�����u���p��M�B�](LV@&q�J]_r��Ԝ́H\��{$ɸ�ogq?�k��5��(Y_���=��E�S���<�*Q�;�*�Z�ˣ#��')�M���2M��v����$�׸�������C�a��6C�N���h��m������i�V����R=t��\��t�����?zp��C,�]u�����|�� �n�Jw�4^3x�_q�y���¤Y&�V�"|O�D�f�|�jO��?]B�h�=���d�׭�L.Z97��D�d{%��(�.��#��%�ys���l�ˁt$��Op5�[��¼�+f�	��'P�v�|����������M�.9u�����	Ԩ�����5"C�K�v���Sը�B���ڒ��9�8txr��e�'�\������-� w�#��/5%\u�����J�?Ix����h�-e��9����?҆c A���`���n=��1��[��1�m���^2ȏ������D�Zh����|����>)�	�>n�{Ҵz�B1�{��h�4&�'%��c�d�$��BpM�Ì�6y��b�����_i��ۃ�Qy?�Yjqˋd�zq��-kJ�/%M4��ޏ�4�c �.l�!���	j�Y��i\��J���Uk�ʷ��5,4v˹k���9���'�2s;M8.�_�o�7����lp&jp
-�L	l^*�B�G��"�Y�P��P���_`̩@\����	����V�jӺ;L�k��MP{��x��^<���g�N|��8��̆��Քɯr���n�ʅ�y�1�4��B�3��֘\l�Pu��:[�`Q���#���4��Ulo�
-&��$��賾�q�"2�!j��/����Z ѳ���J��9�Mͳ�U��(��%�Hkxv3ރ�`��2_���RE 2y)�"�47��<�^˜�����w�.~��
-��~ �I>k��zY$�WɰɰS�.E�d���W9YU6��L�Jv�֭Y�S��3��Q���(Ke];ʺb�����I�w��F�_vd�y�����1�v�Ŋ��q�s;Gm��2;K��4�s:���=�����!�G�~�!��Lm�hM�<����ʪ�ٟlʩk���|]+\�>Jlۣ�`VqWVAQ�f�)"��*(
-�P��hc��*�U���W�Z����)^ӱ�u�Q��V��]r��:F�g)�)F���y���W�R.��Z�ff���j'�_�=��k�;=/
-D_��
-Bk���>�W�x�!��p�J�ٯ���э~���M~�S5';���>��r��U���C|�W�8��DM.Ԝ�B���͇|��n�$�7U�c���`�w���m͕U�'���Q����Lϴ����~�i��N?�*���u�v�%�]M=F�=�����	����\�}*�~y��o��ϣx���T�<��a�p�[��|�Vs�1�,���&�<`j��$
-dgi����Tx}��k.%���0Y���c2���Z��c�^�����������Ϡ'}\�+u�zrF
-��F�o����D��@����������Jނ2�#�xSh7�g�eԺh��Z�/v������2�������y���g�Q��Q��;�x��p1�s'���
-��
-k-��s
-�
-F6#[����ȫf��s��SolX�%;*�v�w#l7�a�Q#���e§ЋF�w��^qY��ze�3.�wW���pg����J�o	Y9�w-����Z½���K^?��XKXO���Y�E�U2[��w���m
-^N�z�m�{����<�?����3r
-	��M�����2�@�������:�d�iI��A*Gy�.��f;V�D��B��Ļ%)�$��1�[�B/G?����b���6ӹj��}s�xΈ.�L+�A��D��[�����/q/��χQ\x�����X!�B��<
-n
-�^��*;O��|�����!���1�����|P�?��xV���x­I]ˇ�~	.0��(c�lc����J&��ks�Y)��v�^�8$��9�.pC�|�W�yO��!<��V�Ou���q}��!,�Ս�V��]�2�CT��֖���(��3�Q��~4��
-�֩��"W�N���i�A����-a��na���؉�!��(퀄KJ���,w"ܧ��:L��xB�5���#�U/�6�nF~Qa ��QF]#5�Ӻ��mS�Â��x@P�e�}~�:��E�TA)�����Obv0B�]��twx1���	2�m��H���Q��Ii
-�/���k�j�
-m6JN��~���R���^�Dt8(�Ш�T;��l��71�z�G���W����]��2(o���z�T~+��Q�ݘ#�Z��5��V��
-��Z��MRw��<�k>����,��x�^�6/�έ��J�#F�s5����z��E�������c�9��	�7�gj�͢ӎ#��0����@*;�i�{�|�+Wv���/5 ����#���HګH(p���t_$9l�~�d��3>���\�����Y�G��U��*4(0�|H��C��L"he�;�����O��p����m���v�������h�MCK�ř]iM}�6�����۰�� E��ꂔyf�ɷgM��5�.�I��5��Z�NQ������ �a[����X��D��B���'m�Bh������WpoGp}@d1Cx���BD����$����8+�虮�DY�M{�̍���y;H���]�w�!X�����NӒh#�3h����X1ּq�S;�0.��`T�oK��Bl2<%:�N)wg_"�!/��_�Tބ��l�3�k���; 3���w\_�P��VE�IV��z�;�5���Q����]|��a�w����l���;�^�#,QX�xk�����>��~/����$�"����_�]���9<:/�w��[�ǵ�%��Ȳ!��p8 n,BJ�%;ٷd*������W!q���Z����t�����>Ǖ��ױTFx���O�v��څ].���������.�n����F�[X�5�
-�vg@�-��� kX��U5X��v��n{�+Az�>W���<í���4m
-%�Cu~G���24'�%r�E��@!�g��|OEo�:,��Az��
-
-��aO��fW? ,E!��76!���Q|r��jWd�M/�Q��>p_ѯp���++:��B������t��.�C6�w̐ts�`���P7sI��]J�R��.������>�?����,�Xh^�5eh�Ϋ���:i�:)D����n��bM��z�%�S��P��A��M�A��/q��.'_��C�kG�Qv���!<����|��%j���m���RdJ�e2�7A+��α�4��i�_��J܍ˡ�q���%㲴��:�q�T��sn�~��]�9�~�v
-S�]F=q�#gꀢ�c��RS�/���a�@G�,ҳh�ar���>�+~����aVٛ����oTi|�b�_��1P�'�U[[[�Ϫ���R��3|��}FM�Р������Mu�W@^5��2���bCt�+H����4��8�It_��w�k�qW�^�_`Azt���{L�A��ol�"����^���1�^Ąg��.24�v�5G� �-C�ӗʕp��jS]76�,��]�T�{���H��A��l�K��,�zI���b�.�9q�]x:��ҪZue�Gx�A���ap�nv"�qm�j�=��t"��t-�/��yD��ne;Q�������~{:S㽦�t�x#��Avfʡ~�u�*��wG؞��
-��,R==t����ĳ@�&�S��3� ��Z���H����td�뿩���]�0����PA�y�V�1ת�m#�j�ꗴ��p[�C��G���$�Z ��l�v�w�\[c��ܴF-m��V��zpPU���U
-윦�͓]���jl��#۪�S�U��DBu}0Tt�����R���-B{vEzom��-|�k�K��.]9��^�����+��.눚�x&A)��N�h�)�VC[[ѯ.����խխ#*j�Z��_V�dsmYEگ�x��\�hgZ��R$m���B���"����C���oQ�l}j�O
-I�=��V�ǐ ��,�
-k8�r���Ӱ~` ծ����=h�Zī�UWV�eqK�l3�W{_��=s5��wbPcP��:�<6j��iH;�*�ӈ�nc_�tР���Lj�^�]O9$��:5�ڍ��,?�3�P��1f*�"Zx��qO�?|�j��Ka��r6`�M �C<��?)�)�����Ct���	�'6E q�`��X7G�V1vsD�m��$��^
-$N\�*�k�2����&�v���b�D���Q�=t�M���BR�,�ι*~�A��\v�J�83+8g�\�s�&�q�Su.NU�sqt�����:<)�H�; �-�sD[s4����u�v�y:�k���9��8X�m���h�����3���!���{���p���u�#ǊF�
-<��C]|�CU��?�[ ķ�Ԯp쫚,I!�VX;�b{���Q)�h�d�6�_�:�8����Z�(��YT1vQώ_���
-���r�x`�-��a��&�[]�	u��*���������y�/>Bg�9�x���!馺����
-�r����
-��u��A�����˜�~j���Z-�vb��,���x���H��,��/�Ǌ�O��~��d��\��l�ee�/���ģ�;�i�NE������&�Z�j�E���µ�gpx�gsx6�gqx����L�%%-�`��sF��W.�͟�٧y93t���-%:��^�~���D�i��b����\^���B�T�|�����)na(w^n��',�k�
-�Z���V�N��I�W�S��Sf(w��u��`Ϙ-�Y�6o�ppt��R���;Z�e�;�������9gZ����ڤ$���N�N���6[Uj�A���g�Z]]���a
-���o����҄A��6�
-0�����g߲Y�y�[�L��.���[Z�2�������bߚL#�hfB�g5�6"�x󀉯xT4���THMW��۲�{�"-m��I\�a���v�ʪD
-��֘]L	��Ӵ�k�B�*��j��L��--[�1�m*�#*�](�CcS�~NH�k�z@���G
-�C��P"���*�g�"�J��������gl2͘�B36:t�I�Z��k2�����JK�Y|���"c����i�����(+sL�Gpy0!�%�b�8{/�{X2P���g �n��b��n�3���7n)�=x��(
-mS�ϣE��<����J���tTvq:*{q��Q���i���?�ap�p�W]��^E���qB���z��$)���W�`�=ښ"��]I�9�d9	
-S�����;�^��5S�q����	�;����=;5��;�X�@׀�<�"���I����)U�jk���r{F}�����wV}��ʞ]��M4��(���_i�]�}?A\q��[��j����	5�n�(�Rl���;,7�Ǟ�1�=C~s�3^cW�����+��Ϊ5TC��6��p�hG��Fn���S���h�v �Mj�>��n�u��b���Z)���;)��~�)5�@����;m,m*%���g.�<+ �OT_s=���W�x� �ߨ�R[7�=HR�h��5�9��N�z����i{]���dG����|f��#5/�F1MA­_��|(�P��>�<T_�y����on")+�\O2U>6+�]�%?�k��k��x�KdWS�/m�j���V�p�c}��\�>"y���	���;�4f���.�9-"�uޙ���5D�?��P�'��ho���!-���&�@?��P��	�} }�M�$�CZb� 4I�)�
-��5"tA��j�ZS�k�+M��%q�-�H���)On�)4���B-�/bH!T�k���2B&���JMm��C�u����jy+�'+8��쪭���D��ˊ���V*�)�O/�������G��gh��T�M~�B��D���;ɻ�If�*3��FU
-!��7^sc#��N�m��ow}�z��^L��;�NZJU{��읕�r��]i?�iO�"=��<���t��e���^�r�N����w����6�G��@���E�I���>4�u\j�:.2E����rl�m}c�(�]�v�"l��z4�_
-��As�h>Z��c��lh���4�xP�6�,�+�d�k?�Ĳ�)�9�4�3���^C��a���>�{=K'�~�~�J7��c^������Kt�D����Ë�;�dp�/k�~�/
-�@�EM#�'�L�;i�~���{��D�M{'E�o��`7%���7(r��f}��΃�ol�?�K��l
-��ܴ��2����۽X=}�Џ�[|��*�R����mO��;��w)��~��^g�O��Ǖ���>��o�}�`�5�8������'b�~Z��Y}��$�s }��K���8J)��Ǹ�W�w�}\��?'t��O�&W�������߈}�+��S�!�*�[�t���P��L�!{մ'4�3��Ć|�nOj ��ې��v{�h2�G�S�7U�S9e�L���T��=��j�Y
-��E�|m4w���k0��i̞��h���z�G��h/h@xaV��G9�1����%]��M�E�^��xs�N�T'�\��o��|y'����nc�kt��dџ�=à�{)4{/�fq4{����fSc���O�Z����������[<)�ykB���v�ok��䷇�������ؿ5�{˱�7��5f�����#]�g�2&�ǁ����֥F�����;C��^9����������� �jW���"��0l4�ؾ�!���6c{͟��G��������c��.�=3��py�+c3�a�>0cW�;8\�Gfl�:L�!3��p��������t�r���χ˛T�.�M4b]fl�{ɈM1b_���Fl���iF�I3�Ɍm6cF�݈=h��:Fl�몋�gľ���k�"V�.F�2ϸ�j�kv��s��b扆ē
-98�B�m��B>
-P�!�j�X���V0e�e<e�e�e������`���9���?c�c@�)F|U��9�4E����E�>�GG/գ���gC���}9�G?h�N@��zt4p���ǆ��إ�=vl���W���mKcv"�=��$���&�|��l�>���w�o�-�N}�v�)U�z�l���L�%������S�tq�v�.n҆���!�x���gw��1;	]<��9��Bo^��F ��0H�Լ�ȼ��oʑ�v0��5f���H0ҷ�I�$&b3M��*{K�����2����3G�����_G/s��2�o.!��f�>��	zY'��x}c�}����x��N���
-Stk��^���c��&��������,E�/$�at`~Q2]�_�}��J����� ��~5P'c�5\\�ӛ(*k/)��i���	���Pt�bTc���\3젡x\�eM�=��kȓ�	H�Q�y��'P�����+�1�����Z>ɕ~'8���35ف�T.;W���-=��kz���k����V�.@/Vаj8z`9� #�W�~��̡���
-�hȞhH���Ɇ�Ɇ@��șٜ�:E�����_�W�i^S���_�Jm�X�b&W�J���go��M������~��UMw�U��'/���6%�X��M�Gc�k�����h,W�����S:=4�6����
-��(M�w�����;q@}�c��ό&��m�P�̗�:BQ���ƶ��-Nf�����K������
-7��m��Q����=�z<��M�������>�;�
-�*)�jX�#����3�̷
-D�����x0����&��F�$�1="�(�;��lZ�I�BI�HE1���ҝ�����N�#�U����������r�(``��}���]��W���Կ��a<�
-ƿ4cن���-tc�q쏎E"�.�n)�D���C���L���A���dA{&zVp;֏Ut�A��+Q���j]��U޹��L�B�$�.�i�,A�U�v����3�_�|�����1�6��C-��%)��h��7G��`@Z^褿0�t?X�==n������?d�Vl�.M�͑�O��'�A]�Fw�<]�>�.��fg��
-5����V�>B����ֻ�A�ix�](.�z�@�~�]���q�i��i�#� �DΪ�.��k����ʏ^ЭS�R��� ã�e¹��.��H1�wSp1W��0���p
-�|�"� �*�TAA��������n�ٻ�~teD�8q�ĉ�s&'������]�k����ۨ�FI��|����+ߡ�gk�;˳��,-=��<������b���R~��B6�sȰ�����8�vR_
-��� m���#��r�vp��lg~6�:���֊�������砆��!��B���c�l�V.�u�!}uhܥ���e[��Z��_�.��B�m����l�&�?l)�������e{�q�Xdܭ�~�E�t����T�[�4�� <ٽS+-��C����b���n���� �:�% z�
-�)%��ħ4�3�c����
-�}?���ol�L"m�o� �X�Ѫx� -���al^��*��h�6�!j�^��ѕ²"f�({`�/!N8�MB��zI�7f����[c��>w���D"���FX�me��E�,L�{���M�=<Xqcm*Uc�ebԌ��^�%ր�{d�΂�1�y�no?R����Wc�Q	�!����*YZ�,-N
-��	K�n (O�4�Q��6}�X�4ի7O�lƩA\��pu{����8;#|���&�G���üƟ}��e~�5��.֠,t*�8��	[t�N-*�_�<
-5�>��&��+!��!��C0��@��a�f��=_C��f�G��4"bV�Q�-1�4��� f�l^'v���8��&1`��
-~���S��_\+��˸�P�h`���^	��
-eA &�W�JT'��@�0� �y7K&��'}QM�D_�7dLz�Ǝ�Z�%�x̪~�S��*�����kP�^��4E~�V-��̉o��.�6Rh`�wBU�ђq�5I��=��d�힎ɞ�@M������ݯe��<����'������NV�$S�
-x�R�@�Y��٧�T�;�B�E��"�e���O�e�=b-�~�R~з*X�%��H�_ �NW���m���6��Zn$�Y��,#����QMo��|�Egp�
-�o�v����d˲A\�ұPuA]%��}"�A�Ezl���~0Tڤ	/�e�í�	l�ߺ,�o��F��(	Uƭۿ�U+1�����1����8e�WO뼚V P5� ��'<*�؇�&ٴk}R+E�S=�wx�9�����|��*wtݾ�[Zz}c�--_��o4�+Z��ү5�M-�EKoh,o������f-_�қ�Up�e�V�z��F[Q�-�����q�� �^S샆�k��kb��P��y��կWK���^-�UK��Xު���toc�_��i�jc�O�o����۵�6-��Xކ�����`�[��a�=�ۙ��v��Ilg>A��JP�ME�CT��!W폄��!��36�
-)��B��R����<YX����$��69C���!{5��!�v��Y��j��������_�8��X:���:��/&W�^����Z%�C�%�Kh�������p���'ŀ��]i-oK/''�*>��4NKb��Q�R��'�-T
-���ֿ����-TS�|��l���t	���%
-�S�W�(��a3ݓȬ�U�U��ɉ�B��T�Dv����� [��br>i�e�&���I|����ugN�$���㭒��'Fi��
-+7��]��.bݤ�e~�Ej��%Q�P"�
-���8�X�,
-4�;d�|�5pflװ�bl:ئ�^�F��O#l��i>:3ҏjH?`������c�dB:م��3#}��� #�f�=5���S�������R��F�����������h���
-����D�=�X�(�����!��cn��B�����������T���(�v��~�n����Z�PzJ�p���(J�q��1�kH�B��=h��~7����2W���l���uE���(Ǫ-�7$��2;':�J���r2D1\ɓ!��IA����
-�$}<Ε��'�����+I�������߃���WT��J�r*yR������ĕĎ>i���\ɶ3N��������*V:�ߓ��S���(�v*��Z"vf�6��d�M��xp�ׂ��L���' lZ P$#�M���|F�	%�G���SR�$�(R��f\o#B�Ǟ'�@��O�*�0Lo��P��\wS��G@�g��6F��)�O)�3C3���!H�[ !9a��!�*-B�#�֋�
-o)Q!�e6�<ۉ�eA�QB��k?a��a����L�v���H��p��r�~�\����I��\פ?$�ҩP�D=|*�;w:�)�<��'�$z=��t��/a�
-���1FO����y���3��a���clu����)ļ�:�{,�ԝ07$HLW���	L�q
-�yX�lαD�e�n\��*�H ;@{�j�Q((x�����}k�@�P��(�<��o��@� ���f��bIIK�?4�CN�q@������?���J&�QG�|ٯJ�� �3�øJ���ȯCH�Yn�㿛e���JU*�=�c�y*��-�T��@v 1t�K��j�'~oB��	�k�<��P=����0�8��S�0�����:���ǄK�*�.�p�T�T�n_���{�ItpE�9͢F}y��FTtE�KF��c���^}1 �-2����v���<��T�����l<\�)c�a9�#�
-�=����F�d5�nt�j���6z��F������<'v�+�X�@�:��{	t��p1�|����ˆ�
-%,P�<��\KO�ʟk�#Zz�V>��k���a �V�r xA�S(�u>+c��{����G��@�8�ݯ��ge�Y_%�{Z��{�jo��նi��(�4�,R�c���7|���~�Ṗ�s@��jS<���
-Z���:=�; r�,M(����ޏ�Y5���:�i��pw��>�Y�ųp��e֔p�@�%�tQ66�]l]LP`�(�?�����ő���.�+���*��:��_�t���XT�3,wk�jz���},g>����'r�|)�-�����#H˺pI�ZZ���#�E�������>w�}�\U>@�(w��D����5T�������	�vʍ��0��#��Zz�����h��~q=3q��;�mץ��'������H�9~�EH��ϒFs�?4b�>2N�����}��+z��O	�=�Y�r��r(i���4,
-Ǳx�-L*Ap4�<���ʄ^��P�c��8?C�L��3�x��F��xʇ��q���_�����W�23���$<��'7b.�3+M=TX�*�Ui��w*�hF`��ɻ�L8�o���C.P�27$~��e������o��`��J{����m��3���o��@�]�PeZ1�v�qG��b��s�\�[;7�E�RjH{��3f�I�#9����Z4�S��Ӑ?wP6Bك�d�gA��#�
-�AZ?�Ve҆i�܅A# ��Q8�$$L��N���lOgbj�+�5��3F�I�sh�o�����揑&��r|N���œӑ~t�	�	� �mAj����j=�Uw��A��j8t:�\�]��su���^��6f@�K����
-�ݗ+b""��(���j�D�fǋF�5j���)��11��yф�#��!~{	� ��j���bY1W��}�0!���+KL�!@:'g,�;�A�̎��Ds�e#l4�2�e����-���fG4��Q���ԷNܺ�Ժ��u�h�a�u��)���G��q�t�;��k���:�ݺ����+���w7ɰl�&n����ib����8���_���<�]1����֩X�\8�8jt�mt�����bGGqtG�,�t/�(�;���(^�Ҫœ�A�#8(WBz�Ƽ`$��<(�0��U��i�$j^�t�2���p7�o�~��o#�R�/��L���[�7N��鷩�xN��ֳ����vM,�g���f��&ha�7'����ʄ��y��I���nN�F��X�0���h���&H����]�SF�b?��сK��;cJ�zqlF�H�<��m���CT�Ŭ4��|�
-�&�8Lk�Q�����&�D]��e`�J���^9�&�&��k�̫q�|���1r܃Q�G5�����z��a`4:D�s�u�P��o�����ޚX�
-~㝃dM�æA#�����2F��"w�3��⻌�]����_�g�s!O�a����Mas��#힬��C4�B=�le��nÂ�؈��^-=�DkzB�̈#���ӆ�݆
-��%<%��\���/������<������ň~Rfk�'屴��%�����..ы+����;�x�
-^�`������Wk�*BsH8��N־O%�3��b�o� �O�\e�9̰���� ���9##R�y=
-U¬i�iR2�I"����M1<���Cj�E�"�ǠE�Mj�R���p䗖i�]cb��1��c�7B�$���&㥔��δb'�na��h�!t��ș�R��@��ٳ���[��YZ0}����,�ւO�҂�õ`ư-�T�.D?�!��_��UH�ƯJ�g��8
-d����J��d�����Ku�U��#;�H�!��2鏎<�������"����*���Qp�Ĝ��O��gb˚x�9#Hr�3�k%�2��0�<�����e��9�Ѯ1˶4���?B����7�
-dE�vy
-��j���e�e=�Y,�Xی��$���yړb�õV���&���9n�fAj��&.`���,�h�f�_#>�x���
-�ۋ	Ƶl��(a&�I��d��5�� �;��S�B�k�F|���;��&���,̠��Y�d��KSi��5�2��!W�,��۔�����&nW�Ȧ�H�vD�,�j���T���d&Xir
-v�ۋ߀wԏRP�>��7x�d̡PG�~1���_��#���9��>��V�`����-��,�t
-w2�M�s~F
-_&��4��#�MQg�����������Em4��b��$)q������ؿ�NJL+����c���j��?�S`��dm�:A8l���uR๡ns�2R�o��FL��>��N�za�Rl�D�P:&�"U?l4��ڏ�z� �Bgn�]�׻xe�Z�	>�o��p��(}�t���*�b���~i�B1hv[U�K#��H1t�{<�oR�7�$6�u���1����1Ŧ��
-���aɁ�#�h��{vw�0����
-�5�>�X�R��ewȒ��+�S$�HI;%{AdZ
-X�p�����Grg�(�
-���<\V�gPA�0��\OF�^h
-V7�뻙��e��d-�g�é�X���vi6��n�<�X�MW�c�eI�/���ͺ�͍������"8��(�X�(z#Z:�u���{�D�G�5J�CFI�5J�ۆ�FIe�(�d�k?*JR�`�7JH!
-\�R�E�V+��ZʿģC�E8�!'�9�>����U^�l�l���[;�E�L>���E��� q�ֽX��d��T-U܍���V�]j�.�K��l�F�/��D�֍���%�Q:�4�q�g`bz�;�x������+9dy4{&�al�ڬ���+�2��u-�*6�-���q`e!3Y	z=8�/���H���������/K���'��㴯����{�~$?�b�����[z_im��_�~�*�@To���#����������1 �J~@���b9�ޔ�l�#��<������G��n�,�V�
-鵽J~��{J���)��=Rz���f(���c�4���(��
-Wc�g�0L���ûb�>'\����Vƿɞ�܁��9@��M�;�m�����𓝙�7�w
-��Jn'Z��S��;vM����+ݞ*ݑ*�J�?�����Ʒ>;U����[xiVJ�:?̴����Ҽ���]��J�ǝ���b����qle�ڠw��W��ޕ�7�"�
-w���ݴ�'���a=B\)}-���2��ޔG��羔�?�3?���?��zU�Y����
-%��0��4�u��駼R�L��4�*ց�hQl"���R�l�.U �w0�°l|
-���JN�j�+̭B7��d�ƼUD��jD���i%����zJ�D��L��D��w
-_s�;�EM�2�Fy*,�J�؈����J��� �PD�V��)*�-n��oI������#�¶�*���������+��/Hb���R�ٷ)w	��88����k��˜{ײ_V$��JX���e�(T���X�33�6�;V�,i�ƚ��b?$�V��1h&Ns�b��F^T`E��	����f�s��"�@�YI�(n��~��y,I�n��/)�m�@\.=���߀�\��{��e�I8w}�2�DJi�9Exv�*��)���>b����矁���b�$�1���)\���8�����=��R|M$!�9
-/�m��D����7�~rH�&�F��=��s��ؽ��Y��#ib�n��YE�(J��(��ӯ���:�0��s`�����	Z��T����m������k���Ә����|���C\�b��!/�3�o��{��#�.�P4�/��\$M���>N����iu�v����~Vc"��3b����!/���%��$�I�a�G�<�Xl�v���0�侓~R�){w��a���	�!)�@�n�l�����o��Z�n��d��S�s!�8?'�e��$G^
-���In�G	M��2e�GO��͜T��B��'qq�G����=�k=V���&��9��8�?�ϯ8�IB�	��+�pu�U�$�Fp���6\�d��/X�t�?p�:�C�c��#��.�����|�]z�w����>���(c� 㣕n>�l��F	������}ˋY�f߽�>|��Ly���<��d暀�iZ�\�yF,=V�<�fϳ��z�
-m�DlU�V-%�ZY��)��Fw������4�~�آ]8*��Q3�0-�	�R--�&8�w�������ߌah�%��z��p7�!@��D��X��?''�T�`)6Y�΋��<�"���R�X0	"���^�f'���;/<�`تE1`�Pj��D$��5�0�V��Ӵ<���V$q�'y*]V�X�q��������z���@|?��)Tޤ�Ӻ�)Z�DqR]�X(0�Ec�!��|���j���� �j4�lQ���b��o�����.-�N�۶�(%�졯��r��LP]�н_�<�(���rC/��b�F��SZ�i^T��%n��wIe;h�E�n
-��J����XOV�:��U4z��8V���J� �U��� ���6����}I�l� �J�Pi5�|���uA�� Q����bӿJ��X��0'N�����O�r�
-7�y�Ҋ� �(��O��\yh]s
-����*�֤Ru�)������L(!�P�4�T�|��E ����
-�
-{���z`���1�*˺`j����P�*�z/.���)�6��/)�.G�|��c
-�T@j���HR5$���B�2�A�P�e�oJ[3�e%��X����]&�{��xb�s�
-`�bS#��x>z�u����Rr�����o�! ���x�����k�ɱ�i-}�V>��'���j�I��)-=O+���_k�9Z�k-Bk��'����6o��X����+���6�3����\�������jF�V57]7]��oU��W{���������w����v���y�5��<U����U���\|j����C^��	 \܁QM�0W�.\�f���]� =��IŠ��X�oa�3U3��J5=yD�3.����P����7��V[;ۗ��^��Lu2�Qv3ZE�&���������/��wr[Ķ!:S�y��w���4��LS%Vĩ�R%��[Q���i �5�jQ��ە���)WnY���J
-������p��-7l<j��P��BF
-w��9��S.��(1QN�&e� �M�k���m1F���)o?ӳZ9j/�Y��_x��u���hiI,��}7��s1��V6v�
-+�Jn[jܶ��@*�lO�"*tn�����e�IkX���}���+�*��ү��y-ɢ�-=�o��S����NJ�e�J����@��nJ_d�)}����Δ>�v���V �0l鼗��'�F��^
-�VP�]�� �qW����x�C���V������
-��n���ZnKiw��{��=�\:՝����=��74����QUSԘAq�
-�ۚ*l�7U�;8�T��q�R�}7V�����ǩOR��)��x�<����]�m�,=wDnt�>uL_�>uY��j�>\�-eV�<�Ĺ��9��A��G�,Ʈ�E�5P�k��!�"��s�����`}_V�/�k��#��"j�[AK���J�9�%��߭^-�b����yD�N�w�G��'��a���1�����ih����7�u>v�[/FN �g�?�G}əQ�iI4V?�!}��tAD��Z�&��u���T�Pエ���OS��F����� �뼥u���x�I��Kۯ����
-�ɝ��������Q���U��S�7�B�����m��}$���w�#��b�11b]Q'4��ZT������?|`�ԥB�z����A��+�׃}��ԡ����&Vn�C�����z�#�Sp\5G�;��N�̡�یǆp�g��f�H*=�~����Ҁ�J~0V��!@z"ABw�tf|�t�i���Z�mn߃Rj.�
-�$Yi�Z��6J4�s���b�S_�a�_�ȇ�	g!��8s��n�P!��Ԍ!�XD�q �}b��S�3�5鵸�RmR�����`��ē`�T��j%��*�0b�G�K�����f������>��tq���G���Lc4��sW	�t�U%;q Ur�3Q��bg^�*!)5TW�0ʓ53�Lٸ�ͤ,8�Ԟ9i��gN�CjϜ�gN�3'왓��y����ߞ�Ͼu�����1w�mb?�%���K��g)u�Ro�	q!F������m�˔�f�
-w�4!��_-���'�;ʓ���ӥ�M�ҶO��N�W��/2ћ�l+��+��-���-��_r��_*��y�a!8r��~k����M"D��+���o��p~
-�9�_�L]|]�[q.~v?m=/_���~<�7���q{��8�l��r���x]�ȊAJ�����# p��,ZQ1����E�R�(�lm T�)5q�$0��DP��啶q7O�WvA[�=/S0�,�^�;ź���qLQ�J����a�bpٖ
-�q#e�=G��}��������'�/�[;g�i\N�����\.u^�_��#����j-Z��҄⨤W�.˜������c�_��V�׵�z��S}~ij���ۑW�e^Us��ZZ��u���c�i@�g�j�h"t3�Ө�c�AAG5$)(4C�yӫ��c_~�g+��na/%�3����]�@�1��.l�TBS	I٭!L�<�ĥ��¬���.����/2Q m�u:�-I�B�+c;e$V����1��IM��Cl��bwW[�k��1%nEP�dOٱ+�y����#k�2���`���X�Te���z��NYP�Bw}GԠ>��v 
-��۹z�n�,���yR�`_C8Y���U*��0	��x+읈/����{����o�Z�޾J�ds�����S���asoeb�O�g�������s�w��N
-0�ѤS��T�ewA�_���`2=;����*����#����l�{��1� ���]˻�ٍ�(��:n����~7T�����Z���6����-,rU�:�D�j���l���F�uBh8���K��������`��uǢ��A�0B����0d���5����Tt����Pj����v�����؛�u��Ei4t��C�Vk;WX16�"8�?UgWO?��pM�Ѓ%I��ܵ����r�M1k|&t
-�Ԡ� $(�6�\X)w�XV��1�������~Oّ�9<.�{.�H�<
-@�8��p�#�v��fW�Z6�vN���.P�.e\�.�:/Sl��=�,�2��٦��d?QWe[�S�d�F�$��e+��@��o
-g/l����{���Y�g��J+�Z��ҽKwZ�4n��½���ļ�U�s��C��zh�SvZWuк��[��"<��<�g[.��+��3�}H�!i�鯨���7�Q�Q��I
-�Ҧ��N��ܠfv��Y�o�v���ƤG��n����ג�ד�ma~йAťz7B+�7�@ٷ����9�����^�^�#֟�Qm��R��v�څ��
-#T��o����Ͱ9��D�~���y�kܰ�D��ُ��}��;|� V9�l����e_K(��� ��L��5�����f|��Vu�pڲ́ �BL6��q��o��!0_�Z
-ڎ��T��B���\Ⱦ��+x�"͐^^6L/�v��.c%<se��𸋶	�O��[C���������ߧ�S�TZ�ve_R%~?��e[.�-��^.�Kn�?�*��x�J:��
-��q{��Zϯj��MM�f���][�53�4���:�-$,�::�Ё$$!DW��	���H���"3���%������|PWFċ׋/"^��w�PƩ�<��:�;�k�+����Z�k�
-d���ͤ>A�r��Խ��fj�����j����rn���o7�6Sw����]f��ݸǴ&��u
-�=�k%�K�^k~���DE��<3D���j[75M��,-�z�JrZZ���g�2�Wa��Q+VR��m�o��UR���`Y���u	q�Z�m�e�l�4�l�rVh�p�q�n<R�S��ԩ�U߻���QI��Ѐ:4��K���Q��"��<��f�=0U$����ԽK����D�9�\*ƛ��;("�F�l��[��QOn
-�`e����O�JP��F��:�����Hnð��M\Xr�j�A(ԗ���^���Sa�Ple���D���ku��e�
-Z:��o a�3�+lB��Nvy4�"*Q�Ku���j�xOU]�6&]��/�Iw1�E��c<����T�$�䓧1.�d#s���w�Z0/)�9���5�V�n�+���m�*ۄPC�����z��%<O�J�ieTRo�VE%����:*��5Q{,*��Z�(��x�8�E�Z��>
-�)�����u$�(�&;��>��lM3��g�4_��P��7��/����]8�w0��9`tèM7�]4��2p={XI�V�E"��l�:;/��t����!x/��)�e����r?mI,P=��/��w���C���$LR�Θ��ʔ�����*�u����*d9w���/�ƴVق�P-)���2
-���j>1�`�U�\_+�cS��2X��O
-�bn��,4(�Mv:П��*D�����k����ҥ�Ю2J�I&���({y�Q�S���4�p(��QD�pG���l����DOTjx�T*d|�g��@�,PԔQ���H(j"ۖ����	��F1w�X�o�0�	d��بv�P�"�y.�%}<�U��ĵ�4�_m����b7qmy�X�/�JV�����^ݩ+~��/;��X,c��i!�U�g��}'��GUbk�G�I�fa�CU���2�?(�$^,x�#0��?凡H�l�A�܎�~��y|b�G;���hf]�S̗��Q�U�W/�
-כShFք��S
-Y+��T��}�I��A��JL�n��DB	u�P�	�Ҳמ:69*���Ho�հ!*Cа@��� kE��G�F�������MO�	���d��G�%�p8�YMc�>�[ڮ�MU*�y�&х[��]�_��\*j���}�f��w�_�
-�q��\�*��}��j�{��us�*`�YM�GmVڏ�`?s2���~���3�l�(Њ�,8*���)��
-��˛wl�yDk�Ƀ�Bb0*GF��`��`�*;$Ȩ��!̴]�Ҩ�Sk���e�`m5�r)�����J/���oܗ>�%ꞣ�VLsߵ�8��#��D[x�4WWHF�U~��q���e>�lZ�Ν}�@�?�i�+��b#��l�^�<6C
-�ʱ������DB�I��h�+�`'�1�y:�17T>����_.�4����@pT���if��	�K�ix;�҃5Qa�h�jm��v����9������L 8�ފ��$9kp��U�D���"p7 �ww��
-����q6�=Pz�E�,�<�H� �YB�,���B� D�[���QQ�p' vQ�$��@�ԅx�\��	�y@<�B<�_�^�����:<��_�Sr�U����.X#�>���
-�`�+t���&� �O����cZ�gA�ԥ-���Z��(��~����{��x��6�5�MM>�Z'=�O�3*��W1,5��j5�7��T[��z^���B�Bh���mF_�6��F��N��UTdm����m2V��O��[�}�c{R�a��Q��͛:�O��~�M�Q��w��أ��~ð���)i�
-�|��N3�]�59��,�r��p����Q6�F��N/�8�Mj{��s{�Z�۵bY�E�Z�3������y�[�%�f���r��-v.��n2|��cJ�� �n�t�(0S��f�ʒ�(����{J&��m�F|��d4nd۪����(c]��:���C�g	TFPF��m�
-�&Z�#N�/�J����?��ϡhۺ1�A��ף�8j?!���+S�Q�s�ğ#Q��?��(�b�(6�b�N�ԗ�����G��8U�J��T��+�ZO��7�[�͘zO2�qp���������D���0���� L�5R�����f�F�E9�P���!�<K�kU��-��r��b�6�!P������i�߰v����H����l���X��o>��jx~ٮP,�ޛ"�#�l�]g$�~k_ �h}�Hj$;\c���.���pĚ������[DLb��X�#��HS|��Y�?�?�|��'��Y���Y��׶KU�G�4$4KEB�]Dy&�@lb��,<qnG�\C]�΅�x/���ߝ[����q?W�:�n�,��cڡ�L���-թ������2��e�I��n���f��w��@0`�g�y̝'L���^�y?:5�^���nՃ��jP�wC��\���V�A��v"�S�?���:i�<�4�,v|`"p�M�Lw:� QG& �@�'�����Y�՗���69�$��@35�v7����a*�|�k��jc�ڵ��Y�o53Z|����� ��}	��5���O�d'��A�>%������!̛2ړ^�8i�&`&�f�ȧ���aA|�0���@����M(7#�_���I���f	�3��_Ke�D����}/�n� ���C����3@������*5�����Y�v���Tt��B�j$Ǣh�@葿9�
-t\���[�� aH�Pn�v43��J�s�R1e��(n}�.�.�D/P%Bv%l�0�����
-�:��%5r1ەeW�
-�[-�1���ٞPT(}�:�X��h���O���"������
-��,髒%��%��d�@�,$�$�o{������i�׉���}&��
-�W��zu<���1��@H;[�D��%�V�t<!V=�_�!HN�q��b�q�4Y��gry�+:'tJ���֝����b�fZ�d�FK~��-�D�'o�a߄��ΩY��7�Tw7(��8_9Ψب�ė��]D�2۷L8cPQ��j	��-Iď{�BD��E)�h�]1}���Ǝi�ӕƪ��d{�v6���+g�p��Z�G����� 5�C�������~���~�����/5�T������}D5-�M.B
-�����'Z3R|�-5�{iP2&�BBYt��>CYt�7\[��lC�+:�>;��d���j'�a��:'Ȧ�XZ
-�(�o�8��������v�f_�ۆ�o�:'���D*r9_.��c�>W���dɿwdɗؼ�H��c/��E��o&6R�0?��U��lѴUۢk��ת5$�
- �&�_��:�>b�q�3�	g���u?$qK;��Ӄ���O�S�Vn-X��3"ĸP�����uX��U�^���rbW�K�\�6+�����VQm+��F9/������*�k.��J�uR)*�|RG���Ǡ
-������;bR�j<�+�Z� Ll
-T0|Ru��T��b�c��^�}F�Z��7�����k8�=l�A{޺I��)��I��-w���!�@�/�Yz|_��k���e<�FC���S|�M['=��4O!;�߃�5���t�}�~5ѯJ�B\�ϻ��o�O��3�k"K&Ѧ$�,��P� D(�[b��� ZH��L����2)�	,�Y�G�x^ϱ>ʓ	������^䯩~��d��Q��L�+2���v&�8ƀ��.��	����U���C��G�@���,���nQ.Ӌ���&�C:L�a8�:I���
-W�k<��+�
-�sd�f��%6�Ny$mۥQ���uR/V(��خ�_%�lS9��b��YȞ�h=,dOs�^��ű�TǬ.��¹R�|�x���Ri5;�;NQ�-��.�)��o�?������n��˧������߉�k�}��u͞xW#�����/��B$,�����YX���a��d�bQ��	4=;;�_Q�Z���&Z��9]�n
-���4L��BӤ����ƍk��FN����a|����E��P�Yd�"�Y^ ����%��r@��~Z���1"ls�<�'�tE����򺺉�
-5�_���4f�41>kX�T��;,v��;�FH]X�Ύ}a�Ѝ��s��k��yⳂ(����4�����]�:~'����*N����+<=0�LS�'��IbN���jk�5��J,2����-����:J��US�R�]5�>ͼ������q�9{O��E�v���G��_B���큦ɐ�j�]�
-�M�l����a�1��ğH+��u�k�>jl{����1l���K�:��_km����& ��.om�bl{�P���+��
-���v�8"Ҷ~�f�Ś�5�I.
-v!�̙1_ݕ�eN0���.��,$x���4hH�o3cx	}�<, ���Z|�~�R+��FA��U�
-�4+(�Ylq��������r�r�7�Ϥ/ ����;�|�!Z�1�>3�����^�.�!7{ ��(�Y�aH� ڊil�{�{jF;�T9�U�����G�ӄ1����)Zq6�K:Q}��Є�-�k\C�rj[��e�96z�y`���T��l��j�z��k�|=�L�2��Đ�d��B�2�0�d�Sb���4�-�y9���y[�A�8��p�W�����G�����x��b�WFR�(�*��GU^ႜ���J����3�U�('�s��%
-������/��F�2���� �J}����9�mxW�M�a%\8�5jS�龄�}N��G��+��QY���eR\��"b{�������M���jz-�f�R5X�jP�LM�g	_E�_3�L��>:X��/|j-��zJ�4Ck��2)�(�	B�]H�k/����N��v�p��1��E���!��#EՂ0�?y\{�,Nä �.���L}���>�B����"Z3���_�cֻ*ǈ��1��E��bZ 0u1��0=0�6&Wl�0�P�ܯݬ��AŜ�(��b�0�+QX�������End��^D�D&�i�9AH	���DCK���,=>Y�B"���Q0���r�\���X��@1X����2��ֻC�Wt��H���5*�r���c0vQ-�y�[ˣյ��H����K��x{�+iÛ��ޣϡ]��uvP6�F;��+��N��Wl�;A���8A~9N�e;����"'����>;���b'�������6x���J��N��N��>*���_~���҇��>��t��A��^S�jwӞ��qw��YwP��x�S�{cS��s8�
-��N���Vn�+7���xW�q���"2E��<�KqSod�8��Jѵ,!ײ\Ƚx�:	F^�ۢ��ᢆ�s�PЀ%Gݯ��j��������z-�z�R#�v�EL��F{[0қ4�	�U'�mᤶ�a�m�#oˌ��5,��?�����Xp�6��dۂ�I<F�J�L�Hm����cq|��{|��Jq�_ӯ���Y&Z/,K~��8Ʀtΰ�׏�qk6�8��G����̘&.u��m�`�8&I�uy���)�$���<i���8��� M�Z�?��Q�?�3(^��1��Z�8]�~J���y�VU>������Qk��8T�Ij��\R3{�/�(���S��	�(��/q��?ݣ�w@='Gz��a��SN0ޏ�Ï8��3�lw�b>�eOM��#;]�ڃ�O*Rϰn�Ju�����9�V���k#5���6�]���n�m7+�V��+����)�w5{͊
-35��˝��0Kb����/���^^�i�&r^�ʖ��'�?a�!�6(�S�����iZWǅ(nې8�����;��<�L&��Qτ�M$Oʌ���)qhA���C��\ޚB2ɐ~��Sy���'n�(�^�1�|cx�QC��e�|&@,>�����~�-n�R{֠�wQ~�j:CefL�w�����F�����v��F蠯\���t��1��k����)�Ĩ����������jj#�S���ܧ�,�8{��T�I�
-Ή�K�lu�t��p��P��^��۫�s<�����fngP�!ǟ�d������4�v9���
-���5%��p�PA	�s%5u^%�$w��9�X���q�%�
-.�5ջ�M�0�I$�ߩp�bm��'�6�S̼�EĄ0X��t�>�Ʊ��:���NzRk<��\�LG3k��f.�]�R�yb����A3���g��.������#D����ݕ�C���F���!%P�~ c$$��q�7?//D�K���A!Q]7P�>�`ѺbfR�b�
-�5]�K.����b���Kݡ�:D�;4�-�����[m����~qJ駽��M[_7V�a_9,�.ó��Ce�+�N���թ�q:/VeH8,)P��
-tr�a��&k��xV)�K�U
-焼�Z���H�;b��$�u�N��Nq�<N��H���/�����[��� ��t����ݝ.��
-�A�X��=�lF�����*tH�Ԯ����K�0��^�Y2����s���%��fC��F����B(����n�����tÓ^��yǉ���.�MY��Wt^&���=i����7��p�)�B��(���ٸM0䣾� �(����F�;�]�f��ͣ1����J�����?跡3>��y�t�a%T��;�8��6z*">@ĒPc�V-j�F|v�?
-S�-㓳P�,*K�ք�ŷ�m�ހ�jU��}�|�]�?RAy��q,�	�sD
-��Ғ?1���mBQ�� L[��(&�~
-B�V�RETbF��LU��"n{��u*�/�=���J�����_;������
-��ԁ���6u�C�х��3y�ec(�~�f)w��Z��E��D)G x��R�:罄�J���\>�Jk�8U��)�R)��N��w�O��&N�s?�)<SŐ
-}���Ԩ�&6	��f���\��8!�=>�$ʳY�N�r�QQJ�����4�k�>k���KkRv}�3%���zV�˾���T�Y͢�7Ĳc֯��f���eӗ�q6��
-9����O�lK婽D�{��'C0�	zܦY?�B@�`��:��Y�6mhI����Tȧ�����]�)���(�#���T�j��q�]�Cq����L>wt�x�j�gSr��S�I �u�<Ih��g.�@|�B�!�5�8�B q�-� 
-* ��mPG�A���l��aE�g���&�g4����A��3��<�x;nm`��6���`o��4�mBV�=����Zro���0�:��컶`�)/��^$���^ga,<Wg=%�6Ѭۤ�JU� ��AM櫏���]p�[��2��!�wP�������z~�z�TY������0� ��8�e+3g��KS�x|fˬ0��Iٻ<��6�ߒx"��|rF_/���Ȯ�&
-N����û���u<���d��SZz�Ly�x9���y��"s��V�m�&Q�E��У����F_t���j|�=������ɷ���5)yXk;L?Z� ����vj�`������v�uo�N���Y��Ұ��ٝ�0�������)�ܮMخIA�nMϊ&_��'^!z3�c�@!�P$��Ft�oJۓ1,�S�p���D/���G�����~T��BDCN��� �r�%���y�U���*�%�h�Z�iU�wh`k_u�y�b8�5*Kh죱
-DZ
-��S�\P�(׈-%�����1��{x��6��b뵶�\��xy��������_��\�= �� ���;o2���W�cb�M`��i�Ff�ωR6�/W&�<+�}�$�|"4�DH�8j��6�%��$����
-"���]� ���i!ǈý�C6i�����v�1��)t����+������w;�g��Bkl�~�۰ie�l&b�
-������p�yϘ]*�Z�K�������]�K�9_�J�KJ��J����&w̏�Ξt��8��q��a�����Gw�����AN�] ��.��@�C4��:?��]���'f�8[}��p;Q����-.�n��V�� ��-�x��#j�C�9z�Dsx|�{y��R�∜�80��<��-f����<��-���_YM,�=w�a5sq�S�6Xl�F)�h��i���.��@�˭�T��
-���Q��|��VyU�?I�/{L�P���1��tL���a�a�.Xtb�.w\E�=<cg�0��?�t����X���~f�ļ�
-��5�m�
--�ha�*�H�OX�ˉ��B�.���E&_�;���t�~�G��%}��	��>������o��
-��d�ފ�Jo�I& �.$�j��-4HE�(Ϯ�1M��?g�!!����;t�$��(fj��D�&� 3+A�~C�ġ���R�.��uX���m7��hQ�
-�>�1;)�P��.
-�2b�q��3J1SC ɏ4b����H��ڴ��w6�R*�\qV���zvE�gs�g���^k[1����7�r*~	W<S��%� >{cr�ޯV��� �ӆ��_ZfI{��>nt_�k}��<���l�q� 
-�~��H���
-	?&�'�(�O,
-��R=�Tw%�L�)�zؑc���#�=���PZ��è=T���7��gAY(�uz3�����s��f|�'��#vW�.ʟ^��#a�'��rۖ�m�)�ӧ�N���y��<��r�(�7$��wB�-��@���v���7�Qo,��X�S�V���z�Z��W��r=��~z�t/�<�����zz%���ӫP��h��2uU6v��g�zT�@�3��ǻ�T����M�X�5�*��G��c���{	����M`�0��ۯ�q�)����]���I8�~NϞ��[��C8:t���6
-�Мܭ� s�;b ���q�N�q҅X�]����x9����6붟+�%"�M�p�}I����5K�xH��
-��.#6*b����\��ȅG��Qݼ��г'L�)�3ec!�݆�ϲ�ǬwxUO�6�)g`�l���P�p���ȿ��hɣ&�GM�YA��"�.43��Ҕ�����zS>t�d�7�ጏ��	 ���I@����E��"_�H'<�@;���
-��i��Y���<�Wt�N�=5�E��T?��׍7	�Cmu������@���o��ԯ��~mo�^��Y�)�[U'��t��:��.Fg�:ý��f!�SL`� 0�;��_�x�_�U���4�į����:�֐$�u�䭿��ʴ>��ތy�£�1;��\D �_��R�TV�He�pV2C����>M��u1��묳����!p�Z����I�&�z�Y�j�C��U�Y����v�3"����hڷ����{�-������h��Q�b'b�|(G��?�sGYsGe�0w�(��A!3Ge�E�n���
-���QE�B������豼�E��O�9��Jޘ��yR�\x�P��A�f-}�d���c�a���ӂ��y�i�N�面��Q5q��ގe߉�B�%u��������	���0z�\]v�Vd#������P��n���p�}=�o��B6�W���u:�D��ͪn��0�b( �k�(�S���Z���A{��x;�xK�h�Ti"�a�N!�c��q&���sԙ�ÑeN�m'8�:C�)��>[Ҩ�30�C��$
-�㺱��D�#ݘ��!<�w�+�a�߶��TłpʎS�>���;�`�'�^����%̓"�����eD�����I,k���AbY9J4�8.�(���@�d���T�o���(r�DQl�-G �P��]� ��A�_	VcDebɿ����*�$IT�����������Z
-:A/��hc�ly�	�ز��N��O��p�~2<���d�5'X�O�_v���d�U'����'�U����\���BAeLC����J��+�w��й��s�m�J�>W:q�T{�t��ҵ�Kz����K�8_j�����{�hR�o+	vɗ�z��G�v�0҆~���r(&v�n�r���:�~���ц���8x�݆��&o�X�A�v����(�<9,�s�I����J���`N�# D�����A�7HA/��<���1���P� ���E��R��ӆ�(���&@i�~x�9��`j����+�W�M�e��=���PKnn(5#Ԛ�Jͤ����4��J�5�r�B�ǁ|F�k;hx�����\��V�H5R�sCy�;;�6;��F�ik��n@\�Y�Bf��*k��B�N�S���цdF�q&���r�:�egP���O��N�Hn�
-'����"���ot��-�m�Z�Aosɸ܎�)�b:q�
-��o�d��B k�� #���$��������$�I��i�y���p�]E�����꠰2=�q6�[���`˄�A��9NϷ�O����^���]��>@����8�)h7۟�ʷ���y=�oi��
--�L�C����6�=�'��V۰�|)�,%���Y��g��M� 2�*���8���v���N�}=R�.w*�>v�Ȯ��3�zH�x���*���k��f����I�L�{��f���dԋ��Q�d�7f�j�Q/@2�$�]�d��$�9$s�%�.ɜ� ɼ��HFw�%4�d�Lh8�|��I2'=e��SE2h7��,�,�I��#���F�����:�k�_-�S�F�t�"v���
-�"Ʊg�8P��2A<f����ʖ�@��p'\�c��nIm�׮f���YB_ZF��9Z�3v+{��N�����<�u3�붍��(W�s4��JDE��X!�S�T_�?�~����=%�5:$��5UV3�/�/d㻌��و���~&>�v5���!1-�eԳ�%F
-�tM]����^��B�7��zLA<��نgl8 ��
-�Z迓���UL��2x>5���5TU1�4ڵ�x��X�4ǈ	觱),��Z 5S���"Q,���6.0=�l-�1��n���v>T�UE�E:�tuv)t�qU��
-Ž�`�w����\����fO>��	�٘.�_I�|��G{�Gs�f�f�A3���e�>Rź|�X��L��Cɒ7~g���|}���dY�"}�`_ ҅.�'��W��:��:��|�t��E�����/(��e�	=n�#Ⱥ��;J��GЈ&�	���r�[���:
-Y�B���x���/(*_�u����u&��r
-���[h{ͤ?�LVfr��e�[N�rQ�
-"�G]�<A��kzl3��u)�t: Ǘ�*:`5'��B������x�����<��K`ւ��j"2�.�]4:�7��c$i��ؠ�k��+�[W���"e����u'���)f��%#I��=Q��vR:�I�������I�]���x�!p��>L��u/q�.��N�Wno����k�אS�C-�á2cy��U �g��
-���Ҟ�&�--�Z���"i��4�Ϲx	� �M����!�̏�[�������if��Mڻ�R��^7L�~a���1�����9޵m�f����|EUws�-0Ev��׻|�hdR��My����n��T���o�NHm��s�֖@_!�6���^����*
-~���2z`��G/S�_��[SQjj����Y/�����u��'�n]<��3}���K�p�Q~�bH@oT ��h���� ���`�)�R��n�Þ꘲�Q���&����J��u\xڲ�^@��P���C4��t�3�d��}�'�{�;�&w2%[��C��!iB���ڟ��x�K<��������yk�?�ܟ������g�?��~V��+�X^悿NgO��:���o%{R.p�v�r��.c��:�"�-j��Xr'm$�^$�}p4t���V,��AL'��qq�2[���Ϛ�P�^�v�f�eΫ\�_@x�@t�Ӕ;�Y�,Ѵ6��J?X'|@Su�y��!
-�q��&��%c�0�*��p ��P(�;�g�O:�����C��M�L���Z@����M��X��%��]j����)ԍ�(��Ҥ�����CG��U&�Nz����Z�����|>���j�%v�$�@>{6IR̾>�����|$�/䥪Y����Ī:U�ȗǩ
-�B�)6��UM�+����6��(f	��"0��YX�G�h��Z�/���S�8�%������/�K��^ �+�4�aZ�/Os[&���AL��Ԥ�j���!j�!�f�Th��H��?� �ƙ�(¡N���Ho�t�Z��[]k ��
-S&�lԳ���4�����yc��@��wo�^�|l� ��C	
-4��� \��c=$6j�
-ù���Λ���e��<No�
-٩���p)���u 4ne�,-�p�sR�%
-�!���W�BO	��K(�%�\&��Z+�!�}�b�"a#*yP@�Z�-��SN��?z�b�
-�Z������Q�'Ox��TU��HJʹZT̹��1k?�4�J1qH(�jӌضc'w���i�"�9��hO��4�a�ڱ�!�
-�-�T�ؾ��X ǆ�x^�.
-{�A�W;�P����)��/�U�PpT�PRqJA�+�x����
-c��R�8%���Mі��ȏfr���R�O������Wy�?f�9;�ɟU$��;���#yeE��ɪ 3��e���I;�&T~�\��rH��3���،R�m%��d�o
-%�RL�Vk�
-������Q��4+�da���=/p_#��<�n�\�Tak#l7�\.�m�X.�'}�D���!�˦%@(QWQ�VAlŕ��&[jm�>�x���Jqr筗ӱ��JEA8�@f�`3�o�s��ɕch
-w�0\�auF�]�}Ȱ�����N�9i�!PΦ���V�\�M^�x�j��A��k�����2s%��2E������ee�ρ�h\�����2uqQ�͙x�t3�*gBLt�̤YOѫ"��� �N>��9���)['�Gz�p��$қ���f�^+�k8�
-�_# <ŭ��>���^-��Z�09�0�#�k��v�FQk��&�F�^W��f��-�)j]��L�݂PS��W}���V)��nO���|��:IA�Ivۀ��d��N�z�T��:�C52G
-�O�v_�T,�j����h�]�ޫ*ژB��P�����	���k����!/yl�Α���
-Ckoo�)C�Q�P���O+�P!x�J�P��|�D�_��;G�*v���G`�ީ���p�Hw-�S�����"-� ��Ž��Z\�vk�=Z�g���{���ڋY������Ԡs խ~�چl��{k���z{�)&�ܪZ9��G��~J�x'��ݢ?o�E�:�cU�[�{㖌^�
-�>E�4�� ��\�U�EF'�;eĕ.m-�ݨ��B`��:��=�_����x��������I/0A�!$��A�5�rs,m�{P.���Q��VC�Ƥ�����К�x�>���Ɓ����ӆ/?/j�Y��44T�����sl��
-�~�p#�]�z���tMZK�l(����\��Š��l������򍗉�ʍ
-מ��:�[��C��|CX'0,�|]3o�c�����n�ct��,9ـ��` >���O6��*?�zӃ�N��~G�t1�
\ No newline at end of file
diff --git skin/adminhtml/default/enterprise/boxes.css skin/adminhtml/default/enterprise/boxes.css
index 49705eb..be5b06f 100644
--- skin/adminhtml/default/enterprise/boxes.css
+++ skin/adminhtml/default/enterprise/boxes.css
@@ -1507,8 +1507,6 @@ ul.super-product-attributes { padding-left:15px; }
 .uploader .file-row-info .file-info-name  { font-weight:bold; }
 .uploader .file-row .progress-text { float:right; font-weight:bold; }
 .uploader .file-row .delete-button { float:right; }
-.uploader .buttons { float:left; }
-.uploader .flex { float:right; }
 .uploader .progress { border:1px solid #f0e6b7; background-color:#feffcc; }
 .uploader .error { border:1px solid #aa1717; background-color:#ffe6de; }
 .uploader .error .progress-text { padding-right:10px; }