const litertMemoryCache = new Map();

window.cacheHas = async function(cacheName, url) {
  return litertMemoryCache.has(`${cacheName}:${url}`);
};

window.cacheGetBlobUrl = async function(cacheName, url) {
  const data = litertMemoryCache.get(`${cacheName}:${url}`);
  return data == null
      ? null
      : URL.createObjectURL(new Blob([data], {
          type: 'application/octet-stream'
        }));
};

window.cachePut = async function(cacheName, url, data) {
  litertMemoryCache.set(`${cacheName}:${url}`, data);
};

window.cacheDelete = async function(cacheName, url) {
  return litertMemoryCache.delete(`${cacheName}:${url}`);
};

window.cacheDeleteCache = async function(cacheName) {
  let deleted = false;
  for (const key of litertMemoryCache.keys()) {
    if (key.startsWith(`${cacheName}:`)) {
      litertMemoryCache.delete(key);
      deleted = true;
    }
  }
  return deleted;
};

window.cacheGetAllKeys = async function(cacheName) {
  return [...litertMemoryCache.keys()]
      .filter((key) => key.startsWith(`${cacheName}:`))
      .map((key) => key.substring(cacheName.length + 1));
};

window.storageRequestPersistent = async function() {
  try {
    return !!(navigator.storage && navigator.storage.persist &&
        await navigator.storage.persist());
  } catch (_) {
    return false;
  }
};

window.storageGetQuota = async function() {
  try {
    const estimate = await navigator.storage.estimate();
    return {usage: estimate.usage || 0, quota: estimate.quota || 0};
  } catch (_) {
    return {usage: 0, quota: 0};
  }
};

window.blobUrlRevoke = function(blobUrl) {
  URL.revokeObjectURL(blobUrl);
};

window.createBlob = function(data) {
  return new Blob([data], {type: 'application/octet-stream'});
};
