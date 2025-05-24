#include "Generated/Scripts.hpp"
#include "World/GZIP.hpp"

#include <QDesktopServices>
#include <QTextStream>
#include <QUrl>

#define ZIP_STATIC
#include <zip.h>

//Multithread Ahh
#include <QtConcurrent>
#include <QFuture>
#include <QThreadPool>
#include <QMutex>
#include <QFutureWatcher>

namespace CppProject
{
	void copyFileAsync(StringType src, StringType dst, std::function<void(bool)> onDone = nullptr)
	{
		QtConcurrent::run([src, dst, onDone]() {
			QFile srcFile(src);
			if (!srcFile.exists()) {
				if (onDone) onDone(false);
				return;
			}

			QFile dstFile(dst);
			if (dstFile.exists()) {
				AddPerms(dstFile);
				if (!dstFile.remove()) {
					WARNING("Could not delete file " + dst.QStr() + ": " + dstFile.errorString());
					if (onDone) onDone(false);
					return;
				}
			}

			AddPerms(srcFile);
			BoolType ok = srcFile.copy(dst);
			if (!ok)
				WARNING("Could not copy file " + src.QStr() + ": " + srcFile.errorString());

			if (onDone) onDone(ok);
		});
	}

	
	RealType lib_open_url(StringType url)
	{
		if (!url.StartsWith("http"))
			url = "file:///" + url;
		return QDesktopServices::openUrl((QString)url);
	}

	RealType lib_execute(StringType file, StringType param, RealType wait)
	{
		return 0.0;
	}
	
	//Run unziping on multithread instead
	RealType lib_unzip(StringType src, StringType dst)
	{
		int err;
		std::string srcStd = src.ToStdString();
		struct zip* za = zip_open(srcStd.c_str(), 0, &err);
		if (!za)
		{
			WARNING("Could not unzip " + src);
			return -1;
		}

		IntType numEntries = zip_get_num_entries(za, 0);
		IntType numFiles = 0, totalFiles = numEntries;

		QMutex counterMutex;
		QAtomicInt filesExtracted = 0;

		QList<QFuture<void>> futures;

		for (int i = 0; i < numEntries; i++)
		{
			struct zip_stat sb;
			if (zip_stat_index(za, i, 0, &sb))
			{
				WARNING("Could not stat file " + StringType(sb.name));
				continue;
			}

			// Skip directories
			if (QString(sb.name).endsWith("/")) {
				totalFiles--;
				continue;
			}

			futures.append(QtConcurrent::run([=, &filesExtracted, &counterMutex]() {
				struct zip_file* zf = zip_fopen_index(za, i, 0);
				if (!zf)
				{
					WARNING("Could not open zip entry " + StringType(sb.name));
					return;
				}

				QString fileName = dst + sb.name;
				QFileInfo info(fileName);
				if (!QDir(info.path()).exists())
					QDir().mkpath(info.path());

				QFile file(fileName);
				AddPerms(file);
				if (!file.open(QFile::WriteOnly))
				{
					WARNING("Could not open destination file " + fileName + ": " + file.errorString());
					zip_fclose(zf);
					return;
				}

				int sum = 0;
				bool readErr = false;
				while (sum != sb.size)
				{
					char buf[1024];
					int readNum = zip_fread(zf, buf, sizeof(buf));
					if (readNum < 0 || file.write(buf, readNum) < 0)
					{
						WARNING("Failed to extract " + StringType(sb.name));
						readErr = true;
						break;
					}
					sum += readNum;
				}

				zip_fclose(zf);
				if (!readErr)
					filesExtracted++;
			}));
		}

		// Wait for all threads to finish
		for (auto& future : futures)
			future.waitForFinished();

		zip_close(za);

		DEBUG("Extracted " + NumStr(filesExtracted.load()) + "/" + NumStr(totalFiles) + " files");
		return filesExtracted == totalFiles;
	}


	RealType lib_gzunzip(StringType src, StringType dst)
	{
		Gzip::Decompress(src, dst);
		return 0;
	}

	RealType lib_file_rename(StringType src, StringType dst)
	{
		QDir srcDir(src);
		if (srcDir.exists()) // Directory rename
		{
			QDir dstDir(dst);
			if (dstDir.exists() && !dstDir.removeRecursively())
				WARNING("Could not remove directory " + dst);

			BoolType ok = srcDir.rename(src, dst);
			if (!ok)
				WARNING("Could not rename directory " + src);

			return ok;
		}

		// File rename
		QFile srcFile(src);
		if (!srcFile.exists())
			return false;

		QFile dstFile(dst);
		if (dstFile.exists())
		{
			AddPerms(dstFile);
			if (!dstFile.remove())
				WARNING("Could not delete file " + dst.QStr() + ": " + dstFile.errorString());
		}

		AddPerms(srcFile);
		BoolType ok = srcFile.rename(dst);
		if (!ok)
			WARNING("Could not rename file " + src.QStr() + ": " + srcFile.errorString());
		return ok;
	}

	RealType lib_file_copy(StringType src, StringType dst)
	{
		copyFileAsync(src, dst); // fire-and-forget
		return true; // always returns instantly; doesn't wait
	}


	RealType lib_file_delete(StringType fn)
	{
		QFile file(fn);
		if (!file.exists())
			return false;

		AddPerms(file);
		BoolType ok = file.remove();
		if (!ok)
			WARNING("Could not delete file " + fn.QStr() + ": " + file.errorString());
		return ok;
	}

	RealType lib_file_exists(StringType file)
	{
		return QFile::exists(file);
	}

	RealType lib_directory_create(StringType dir)
	{
		BoolType ok = QDir().mkpath(dir);
		if (!ok)
			WARNING("Could not create directory " + dir);
		return ok;
	}

	RealType lib_directory_delete(StringType dir)
	{
		BoolType ok = QDir(dir).removeRecursively();
		if (!ok)
			WARNING("Could not delete directory " + dir);
		return ok;
	}

	RealType lib_directory_exists(StringType dir)
	{
		return QDir(dir).exists();
	}

	RealType lib_json_file_convert_unicode(StringType src, StringType dst)
	{
		return lib_file_copy(src, dst);
	}
}
