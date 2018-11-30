# Introduction

## DAPP Ideas

* Mixin Pay 类似于现在线下店使用的服务
* Mixin Donation 类似于现在 paypal 捐赠服务的东西
* Mixin School 开发一个在线商城，使用 Mixin 的用户系统和支付服务

This is Term, and this is Another Term

```javascript
const config = require('config');
const OCAPClient = require('@arcblock/ocap-js');
const ErrorCatcher = require('async-error-catcher').default;

const supportedDataSource = ['btc', 'eth'];
const clients = {};
supportedDataSource.forEach(dataSource => {
  clients[dataSource] = new OCAPClient({
    dataSource,
    httpEndpoint: ds => `${config.get('server.ocapBase')}/${ds}`,
    accessKey: config.ocap.accessKey,
    accessSecret: config.ocap.accessSecret,
  });
});

const strip0x = uuid => (uuid.startsWith('0x') ? uuid.slice(2) : uuid);

const generateHandler = (method, paramKey) => ErrorCatcher(async (req, res) => {
  const { uuid, dataSource } = req.params;
  const { cursor, size } = req.query;

  if (!dataSource) {
    return res.status(400).jsonp({ errmsg: '`dataSource` param is required' });
  }
  if (!supportedDataSource.includes(dataSource)) {
    return res.status(400).jsonp({ errmsg: '`dataSource` is not supported' });
  }
  if (!uuid) {
    return res.status(400).jsonp({ errmsg: '`uuid` param is required' });
  }

  const client = clients[dataSource];
  if (typeof client[method] !== 'function') {
    return res.status(500).jsonp({ errmsg: 'invalid data fetch middleware' });
  }

  const cleanUUID = dataSource === 'eth' ? strip0x(uuid) : uuid;
  const paging = { size: Number(size) || config.ocap.pageSize };
  if (cursor) {
    paging.cursor = cursor;
  }

  const { [method]: result } = await client[method](
    {
      [paramKey]: cleanUUID,
      paging,
    },
    {
      ignoreFields: [
        'data.parent',
        'data.publicKey',
        'data.from.pubKey',
        'data.to.pubKey',
        'data.traces',
      ],
    }
  );

  return res.jsonp(result);
});

module.exports = {
  init(router) {
    router.get(
      '/:dataSource/transactionsBySender/:uuid',
      generateHandler('transactionsByAddress', 'sender')
    );
    router.get(
      '/:dataSource/transactionsByReceiver/:uuid',
      generateHandler('transactionsByAddress', 'receiver')
    );
    router.get('/:dataSource/account/:uuid', generateHandler('accountByAddress', 'address'));
    router.get('/:dataSource/transaction/:uuid', generateHandler('transactionByHash', 'hash'));
    router.get('/:dataSource/block/:uuid', generateHandler('blockByHash', 'hash'));
  },
};
```
