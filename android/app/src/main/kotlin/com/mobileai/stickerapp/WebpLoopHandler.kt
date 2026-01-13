package com.mobileai.stickerapp

import android.util.Log
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

/**
 * Handler để set loop count cho animated WebP
 * 
 * Animated WebP format:
 * - RIFF header (12 bytes)
 * - WEBP chunk (4 bytes)
 * - ANIM chunk (optional, contains loop count)
 * - ANMF chunks (frames)
 * 
 * Loop count được lưu trong ANIM chunk:
 * - Chunk header: "ANIM" (4 bytes)
 * - Chunk size: 6 bytes (unsigned int, little-endian)
 * - Background color: 4 bytes (BGRA)
 * - Loop count: 2 bytes (unsigned short, little-endian, 0 = infinite)
 */
object WebpLoopHandler {
    private const val TAG = "WebpLoopHandler"
    
    // WebP chunk signatures
    private const val RIFF_SIGNATURE = "RIFF"
    private const val WEBP_SIGNATURE = "WEBP"
    private const val ANIM_CHUNK = "ANIM"
    private const val ANMF_CHUNK = "ANMF"
    
    /**
     * Set loop count cho animated WebP file
     * @param filePath Đường dẫn đến file WebP
     * @param loopCount Số lần loop (0 = infinite loop)
     * @return true nếu thành công, false nếu thất bại
     */
    fun setLoopCount(filePath: String, loopCount: Int = 0): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) {
                Log.e(TAG, "File does not exist: $filePath")
                return false
            }
            
            val bytes = file.readBytes()
            val result = setLoopCountInBytes(bytes, loopCount)
            
            if (result != null) {
                // Write modified bytes back to file
                FileOutputStream(file).use { fos ->
                    fos.write(result)
                    fos.flush()
                }
                Log.i(TAG, "Successfully set loop count to $loopCount for: $filePath")
                true
            } else {
                Log.e(TAG, "Failed to set loop count for: $filePath")
                false
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting loop count", e)
            false
        }
    }
    
    /**
     * Set loop count trong WebP bytes
     * @param bytes WebP file bytes
     * @param loopCount Số lần loop (0 = infinite)
     * @return Modified bytes hoặc null nếu thất bại
     */
    private fun setLoopCountInBytes(bytes: ByteArray, loopCount: Int): ByteArray? {
        try {
            // Check RIFF header
            if (bytes.size < 12) {
                Log.e(TAG, "File too small to be a valid WebP")
                return null
            }
            
            val riffSignature = String(bytes, 0, 4)
            val webpSignature = String(bytes, 8, 4)
            
            if (riffSignature != RIFF_SIGNATURE || webpSignature != WEBP_SIGNATURE) {
                Log.e(TAG, "Not a valid WebP file")
                return null
            }
            
            // Check if file is animated WebP (has ANMF chunks)
            val hasAnmfChunks = findChunk(bytes, ANMF_CHUNK) != -1
            Log.d(TAG, "File is animated WebP: $hasAnmfChunks")
            
            // Search for ANIM chunk
            var animChunkIndex = findChunk(bytes, ANIM_CHUNK)
            Log.d(TAG, "ANIM chunk found at index: $animChunkIndex")
            
            if (animChunkIndex == -1) {
                // ANIM chunk không tồn tại, cần tạo mới
                // ANIM chunk phải được đặt ngay sau WEBP signature (offset 12)
                // WebP format: RIFF (4) + size (4) + WEBP (4) + chunks...
                val insertIndex = 12 // After RIFF header + WEBP signature
                
                // Tạo ANIM chunk mới
                val animChunk = createAnimChunk(loopCount)
                
                // Insert ANIM chunk vào sau WEBP signature
                val newBytes = ByteArray(bytes.size + animChunk.size)
                System.arraycopy(bytes, 0, newBytes, 0, insertIndex)
                System.arraycopy(animChunk, 0, newBytes, insertIndex, animChunk.size)
                System.arraycopy(
                    bytes, insertIndex,
                    newBytes, insertIndex + animChunk.size,
                    bytes.size - insertIndex
                )
                
                // Update RIFF size (bytes 4-7, little-endian)
                // RIFF size = total file size - 8 (không tính RIFF header 4 bytes + size 4 bytes)
                val newRiffSize = newBytes.size - 8
                newBytes[4] = (newRiffSize and 0xFF).toByte()
                newBytes[5] = ((newRiffSize shr 8) and 0xFF).toByte()
                newBytes[6] = ((newRiffSize shr 16) and 0xFF).toByte()
                newBytes[7] = ((newRiffSize shr 24) and 0xFF).toByte()
                
                Log.d(TAG, "Created new ANIM chunk at offset $insertIndex, loop count=$loopCount")
                return newBytes
            } else {
                // ANIM chunk đã tồn tại, chỉ cần update loop count
                val animChunkSize = readUInt32LE(bytes, animChunkIndex + 4)
                if (animChunkSize < 6) {
                    Log.e(TAG, "ANIM chunk too small")
                    return null
                }
                
                // Loop count nằm ở offset 12 từ đầu ANIM chunk
                // Format: "ANIM" (4 bytes) + size (4 bytes) + background color (4 bytes, BGRA) + loop count (2 bytes)
                // Offset = 4 + 4 + 4 = 12
                val loopCountOffset = animChunkIndex + 12
                if (loopCountOffset + 2 > bytes.size) {
                    Log.e(TAG, "Loop count offset out of bounds")
                    return null
                }
                
                // Update loop count (2 bytes, little-endian)
                bytes[loopCountOffset] = (loopCount and 0xFF).toByte()
                bytes[loopCountOffset + 1] = ((loopCount shr 8) and 0xFF).toByte()
                
                Log.d(TAG, "Updated existing ANIM chunk loop count to $loopCount at offset $loopCountOffset")
                return bytes
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing WebP bytes", e)
            return null
        }
    }
    
    /**
     * Tìm chunk trong WebP file
     * @param bytes WebP bytes
     * @param chunkName Tên chunk (4 bytes)
     * @return Index của chunk hoặc -1 nếu không tìm thấy
     */
    private fun findChunk(bytes: ByteArray, chunkName: String): Int {
        var index = 12 // Start after RIFF header
        
        while (index + 8 <= bytes.size) {
            val currentChunk = String(bytes, index, 4)
            if (currentChunk == chunkName) {
                return index
            }
            
            // Skip to next chunk
            val chunkSize = readUInt32LE(bytes, index + 4)
            index += 8 + chunkSize // 8 bytes header + chunk size
            
            // Chunk size must be even (padding)
            if (chunkSize % 2 != 0) {
                index += 1
            }
        }
        
        return -1
    }
    
    /**
     * Tạo ANIM chunk mới
     * @param loopCount Số lần loop (0 = infinite)
     * @return ANIM chunk bytes
     */
    private fun createAnimChunk(loopCount: Int): ByteArray {
        val chunk = ByteArray(14) // 4 (name) + 4 (size) + 4 (background) + 2 (loop)
        
        // Chunk name: "ANIM"
        chunk[0] = 'A'.code.toByte()
        chunk[1] = 'N'.code.toByte()
        chunk[2] = 'I'.code.toByte()
        chunk[3] = 'M'.code.toByte()
        
        // Chunk size: 6 bytes (4 bytes background + 2 bytes loop)
        val chunkSize = 6
        chunk[4] = (chunkSize and 0xFF).toByte()
        chunk[5] = ((chunkSize shr 8) and 0xFF).toByte()
        chunk[6] = ((chunkSize shr 16) and 0xFF).toByte()
        chunk[7] = ((chunkSize shr 24) and 0xFF).toByte()
        
        // Background color: 0x00000000 (transparent black)
        chunk[8] = 0
        chunk[9] = 0
        chunk[10] = 0
        chunk[11] = 0
        
        // Loop count: 2 bytes, little-endian
        chunk[12] = (loopCount and 0xFF).toByte()
        chunk[13] = ((loopCount shr 8) and 0xFF).toByte()
        
        return chunk
    }
    
    /**
     * Đọc unsigned int 32-bit little-endian
     */
    private fun readUInt32LE(bytes: ByteArray, offset: Int): Int {
        if (offset + 4 > bytes.size) {
            throw IOException("Out of bounds")
        }
        return (bytes[offset].toInt() and 0xFF) or
               ((bytes[offset + 1].toInt() and 0xFF) shl 8) or
               ((bytes[offset + 2].toInt() and 0xFF) shl 16) or
               ((bytes[offset + 3].toInt() and 0xFF) shl 24)
    }
}
