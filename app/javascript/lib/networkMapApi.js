// Talks to PopsController / NetworkDevicesController / NetworkConnectionsController /
// NetworkMapController / KmlImportsController.
//
// Usage:
//   const api = createNetworkMapApi({ subdomain: 'acme' });
//   <NetworkMap api={api} accountSubdomain="acme" routers={routers} />

const KIND_TO_PATH = { pop: 'pops', device: 'network_devices', connection: 'network_connections' };

export function createNetworkMapApi({ subdomain, baseUrl = '' } = {}) {
  const jsonHeaders = () => ({
    'Content-Type': 'application/json',
    'X-Subdomain': subdomain,
  });

  async function req(path, opts = {}) {
    const res = await fetch(`${baseUrl}${path}`, {
      credentials: 'include', // JWT cookie auth, not Devise
      headers: jsonHeaders(),
      ...opts,
    });
    if (!res.ok) {
      const body = await res.json().catch(() => ({}));
      throw new Error(body.error || (body.errors || []).join(', ') || `Request failed: ${res.status}`);
    }
    if (res.status === 204) return null;
    return res.json();
  }

  return {
    fetchAll: () => req('/network_map.json'),

    createPop: (pop) => req('/pops', { method: 'POST', body: JSON.stringify(pop) }),
    createDevice: (device) => req('/network_devices', { method: 'POST', body: JSON.stringify(device) }),
    createConnection: (conn) => req('/network_connections', { method: 'POST', body: JSON.stringify(conn) }),

    updateNode: (kind, id, data) =>
      req(`/${KIND_TO_PATH[kind]}/${id}`, { method: 'PATCH', body: JSON.stringify(data) }),

    deleteNode: (kind, id) => req(`/${KIND_TO_PATH[kind]}/${id}`, { method: 'DELETE' }),

    syncStatus: () => req('/network_map/sync', { method: 'POST' }),

    importKml: async (file) => {
      const form = new FormData();
      form.append('file', file);
      const res = await fetch(`${baseUrl}/network_map/kml_import`, {
        method: 'POST',
        credentials: 'include',
        headers: { 'X-Subdomain': subdomain }, // no Content-Type — browser sets multipart boundary
        body: form,
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(body.error || 'Import failed');
      }
      return res.json();
    },
  };
}