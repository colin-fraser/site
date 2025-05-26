export const handler = async (event) => {
  const qs = event.rawQuery ? `?${event.rawQuery}` : '';
  const zapHook = process.env.ZAP_HOOK_URL;
  const relayToken = process.env.RELAY_TOKEN;

  // minimal gate-check
  const tokenOK =
    event.queryStringParameters?.token === relayToken;
  if (!tokenOK) {
    return { statusCode: 401, body: 'Unauthorized' };
  }

  try {
    const resp = await fetch(`${zapHook}${qs}`);
    const text = await resp.text();
    return {
      statusCode: 200,
      body: `Forwarded – Zapier responded ${resp.status}: ${text.slice(0,80)}`
    };
  } catch (err) {
    return { statusCode: 500, body: `Relay error: ${err.message}` };
  }
};
