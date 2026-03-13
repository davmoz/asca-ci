/**
 * The Forgotten Server - a free and open-source MMORPG server emulator
 * Copyright (C) 2019  Mark Samman <mark.samman@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#include "otpch.h"

#include "rsa.h"

#include <openssl/err.h>
#include <openssl/evp.h>
#include <openssl/pem.h>

#ifndef RSA_NO_PADDING
#define RSA_NO_PADDING 3
#endif

#include <fstream>
#include <sstream>

RSACipher::~RSACipher()
{
	if (pkey) {
		EVP_PKEY_free(pkey);
	}
}

void RSACipher::decrypt(char* msg) const
{
	if (!pkey) {
		return;
	}

	EVP_PKEY_CTX* ctx = EVP_PKEY_CTX_new_from_pkey(nullptr, pkey, nullptr);
	if (!ctx) {
		return;
	}

	EVP_PKEY_decrypt_init(ctx);
	EVP_PKEY_CTX_set_rsa_padding(ctx, RSA_NO_PADDING);

	size_t outLen = 128;
	EVP_PKEY_decrypt(ctx, reinterpret_cast<unsigned char*>(msg), &outLen,
	                 reinterpret_cast<const unsigned char*>(msg), 128);

	EVP_PKEY_CTX_free(ctx);
}

void RSACipher::loadPEM(const std::string& filename)
{
	std::ifstream file{filename};
	if (!file.is_open()) {
		throw std::runtime_error("Missing file " + filename + ".");
	}

	std::ostringstream oss;
	oss << file.rdbuf();
	std::string pemData = oss.str();

	BIO* bio = BIO_new_mem_buf(pemData.data(), static_cast<int>(pemData.size()));
	if (!bio) {
		throw std::runtime_error("Failed to create BIO for PEM data.");
	}

	pkey = PEM_read_bio_PrivateKey(bio, nullptr, nullptr, nullptr);
	BIO_free(bio);

	if (!pkey) {
		throw std::runtime_error(std::string("Error reading RSA private key: ") +
		                         ERR_error_string(ERR_get_error(), nullptr));
	}
}
