# SHA256_fpga
https://openwsn.atlassian.net/wiki/spaces/~712020480eb126123d4999a7c5efa4f829d424/pages/3168993281/Intership+January-+March+2025?force_transition=784d315f-421c-4907-b37a-8771ff92d8e6

/\*<!\[CDATA\[\*/ div.rbtoc1742570880829 {padding: 0px;} div.rbtoc1742570880829 ul {list-style: default;margin-left: 0px;padding-left: ;} div.rbtoc1742570880829 li {margin-left: 0px;padding-left: 0px;} /\*\]\]>\*/

*   [Secure Hash Algorithm 256 bits (SHA-256)](#IntershipJanuary-March2025-SecureHashAlgorithm256bits(SHA-256))
    *   [Pseudocódigo](#IntershipJanuary-March2025-Pseudocódigo)
    *   [Variables/operations analysis](#IntershipJanuary-March2025-Variables/operationsanalysis)
    *   [Finite State Machine SHA 256](#IntershipJanuary-March2025-FiniteStateMachineSHA256)
    *   [Series block diagram](#IntershipJanuary-March2025-Seriesblockdiagram)
    *   [Data-Flow Diagram (DFM) SHA256](#IntershipJanuary-March2025-Data-FlowDiagram(DFM)SHA256)
    *   [Scheduling Diagrams](#IntershipJanuary-March2025-SchedulingDiagrams)
    *   [Procesos paralelizables](#IntershipJanuary-March2025-Procesosparalelizables)
    *   [Testbench](#IntershipJanuary-March2025-Testbench)
*   [P256](#IntershipJanuary-March2025-P256)
*   [AES](#IntershipJanuary-March2025-AES)

Secure Hash Algorithm 256 bits (SHA-256)
========================================

It is a **cryptographic hash function** that allows us to generate a **256-bit (32-byte)** string from any input size. It is part of the **SHA-2** family of functions.

some features:

*   The **output** length is always **256 bits**.
    
*   It is much **more secure** than **SHA-1** and **MD5**.
    
*   It is **faster than SHA-512** but less secure. This is because SHA-512 generates a 512-bit string, making it more secure but slower in communication. Nevertheless, the security provided by SHA-256 is quite high.
    

Before presenting the pseudocode, I will explain the SHA-256 function step by step.

First, we receive the message and perform the **padding** process. In this stage, the message is padded until it reaches a length that is a multiple of 512 bits. Once the **padding** is complete, we move to the **expand state**, where the padded message is divided into 512-bit blocks. Each block is then broken down into **16 words of 32 bits**, which we will call w\_j\[i\] (where i is the index of the word within block j).

From these 16 words, we apply a specific expansion algorithm to generate the **remaining 49 words**, thus obtaining a total of **64 words of 32 bits per block**.

Once the expansion is complete, we move to the **process** state, where the **registers** are initialized with the **initial hash values**. These values are well-known constants derived from the **truncated square roots of the first eight prime numbers**.

In this stage, a series of **iterations** are executed to update the registers. Once the iterations are complete, the register values are updated with the new hash values.

If the message contains **more than one block**, they must be processed in **order**, from the **first to the last**. This is crucial because **each block will use the hash values computed in the previous block as its initial values**.

Finally, in the **Hash\_update** state, we concatenate the obtained hash values to generate the **final hash** of the message, which will have a length of **256 bits**.

Pseudocódigo
------------

*   SHA256\_digest
    
    ```java
    SHA256_digest(message_in, message_len[255:0])
      //The message of n bytes and its length are received; it can have any length.
    
      //variable buffer_size controlamos la parte que queremos usar del buffer de tamaño fijo de 1536 bits
      if message_len < 447 
        buffer_size = 512
      else if message_len < 959
        buffer_size = 1024
      else
        buffer_size = 1536
     
      //Call the package and the process
      for j from 0 to N-1 do:
        buffer[j] <- Padding(message_in[j])    // buffer[N][]
        w_j <- Expand(buffer[j])
      H <- H_0   // init H
      for j from 0 to N-1:
        H <- Process(w_j, H)
    return H
    ```
    
    *   sha256\_pkg
        
        ```java
        //Package of function and constant
        
        //Initialize the hash values 
        //(first 32 bits of the fractional parts of the square roots of the first 8 primes 2..19)
        
        H[i] = 32'h6a09e667, 32'hbb67ae85, 32'h3c6ef372,
            32'ha54ff53a, 32'h510e527f, 32'h9b05688c,
            32'h1f83d9ab, 32'h5be0cd19
            
        //Initialize the array of 64 constants K of 32 bits
        //first 32 bits of the fractional parts of the cube roots of the first 64 primes 2..311
        
        K[64:0] = 32'h428a2f98, 32'h71374491, 32'hb5c0fbcf, 32'he9b5dba5,
                ....
                 32'h90befffa, 32'ha4506ceb, 32'hbef9a3f7, 32'hc67178f2
        
        //We define the right rotation functions (rotr)
        Start function rotr <- rotr(x,n)
          (x >>n) | (x << (32-n))
        End function
        
        //We defined the expand functions (sigma_0, sigma_1) and compresion (Sigma_0, Sigma_1, Choose (Ch) and Majority(Maj))
        
        Start function sigma_0 <- sigma_0(x)
          sigma_0  =   rotr(x, 7) XOR rotr(x, 18) XOR (x >> 3)
        End function
        
        Start function sigma_1 <- sigma_1(x)
          sigma_1  =   rotr(x, 17) XOR rotr(x, 19) XOR (x >> 10)
        End function
        
        Start function Sigma_1 <- Sigma_1(x)
          Sigma_1  =   rotr(x, 2) XOR rotr(x, 13) XOR rotr(x, 22)
        End function
        
        Start function Sigma_2 <- Sigma_2(x)
          Sigma_2  =   rotr(x, 6) XOR rotr(x, 11) XOR rotr(x, 25)
        End function
        
        Start function Ch <- Ch(x,y,z)
          Ch  = (x & y) XOR (~x & z)
        End function
        
        Start function Maj <- Maj(x,y,z)
          Maj = (x & y) XOR (x & z) XOR (y & z)
        End function
        ```
        
    *   Padding ()
        
        ```java
        //With the message fully received, we start with the Padding.
        
        Start function buffer_main <- Padding(buffer_main, message_len)
        
          append '1' bits  //At the end of the message
          append k bits of '0'  //until the condition is met (message_len + 1 + k +64) be a multiple of 524, with the smallest possible number
          append message_lens as a 64-bit big-endian integer
        
        End function
        ```
        
    *   Expand ()
        
        ```java
        Start function w_j <- Expand(buffer_main)
        
          //We divide the bit string into blocks of 512 bits each.
          //N is the number of blocks obtained
        
          for j to N do
            We create an array of 64 elements of 32 bits per word w[63:0].
            We store the first 16 32-bit words w[0..15] which gives us a 512-bit block.
            //Now we extend the 16 words to the rest of the array with
            for i from 16 to 63 do
              w_j[i] = sigma_0(w_j[i-15]) + w_j[i-16] +sigma_1(w_j[i-2]) + w_j[i-7]  
            end for
          end for
        
        End function
        ```
        
    *   Process ()
        
        ```java
        H[0], H[1], H[2], H[3], H[4], H[5], H[6], H[7] <- Process(w_j)
        
          for j to N do
            //First we initialize the registers
            a,b,c,d,e,f,g,h = H[0],H[1],H[2],H[3],H[4],H[5],H[6],H[7]
        
            //Then we start the calculation of the registers
            for t from 0 to 63 do
              T1 = h + Sigma_1(e) + Ch(e,f,g) + k[t] + w[t]
              T2 = Sigma_0(a) + Maj(a,b,c)
              h = g
              g = f
              f = e
              e = d + T1
              d = c
              c = b
              b = a
              a = T1 + T2
            end for
          
            //We define the recurrence relation for the i-th value of the hash h^i
            H[0]^(i) = a + H[0]^(i-1)
            H[1]^(i) = b + H[1]^(i-1)
            H[2]^(i) = c + H[2]^(i-1)
            H[3]^(i) = d + H[3]^(i-1)
            H[4]^(i) = e + H[4]^(i-1)
            H[5]^(i) = f + H[5]^(i-1)
            H[6]^(i) = g + H[6]^(i-1)
            H[7]^(i) = h + H[7]^(i-1)
          end for
        
        End function
        ```
        
    *   Hash\_update()
        
        ```java
        hash256_digest <- Hash_update(H[0], H[1], H[2], H[3], H[4], H[5], H[6], H[7])
        
          //Finally, once the value of the N-enesimo hash has been calculated (N for the number of blocks that have been divided), we concatenate the values to obtain the value of the final hash
          hash256_digest [255:0] = H[0] append H[1] append H[2] append H[3] append H[4] append H[5] append H[6] append H[7]
        
        End function
        ```
        

Variables/operations analysis
-----------------------------

*   **Input signals**
    
    *   The input signal `message_in` has a size of **8 bits** to input the message in parts.
        
    *   The input signal `message_len` has a size of **256 bits** in order to **store the total size** of the message in bits.
        
*   **Output signals**
    
    *   The sha256\_digest output signal has a size of **256 bits** in order to store the SHA256 result.
        

To receive the message, we use a **512-bit buffer** that will be receiving the message in **8-bit chunks**. Once the message is complete or fully received, the **information is stored** in a **buffer** called `block_1`, after which the buffer is cleared, and receiving continues. A **minimum of 3 blocks** will be needed to fully receive messages from **EDHOC.** By reading the code at line 36 in the GitHub repository ([https://github.com/openwsn-berkeley/lakers/blob/main/shared/src/lib.rs](https://github.com/openwsn-berkeley/lakers/blob/main/shared/src/lib.rs) ), we can see that the **maximum possible message length is 1024 bits**, meaning we will need three blocks to receive the message without any issues.

*   Padding function:
    
    *   To know the number of blocks needed `message_len` must meet the following conditions:
        
        *   If `message_len <447 bits`, a single block will be used
            
        *   If `447 < message_len < 959 bits`, two blocks will be used
            
        *   If `959 < message_len < 1471 bits`, three blocks will be used
            
*   Expand function
    
    *   The **for** loop on line 10 calculates the **remaining 48 words of 32 bits** for a block, while the **for** loop on line 6 applies this process to **all the blocks.**
        
        This calculation can be **parallelized**, as each word generated is **independent of other blocks**. Additionally, it is possible to implement a **pipeline-type parallelization**, allowing the words of **two blocks to be calculated simultaneously**, thereby optimizing performance.
        
*   Process function
    
    *   The **loop** starting at line 1 indicates that the **entire Process** state will be calculated for **each 512-bit block**.
        
    *   The registers **a,b,c,d,e,f,g,h** are **32-bit variables each**. Initially, these registers are assigned the **values of the truncated square roots of the first eight prime numbers**. These **constants** are defined in line 6 of the `sha256_pkg` package. However, when processing more than one block, the values of these registers are **updated at the end of each iteration**, using the **result of the previous block** as new input.
        
    *   Since the values of the **registers depend** on the calculations made in the **previous** block, it is **not possible to parallelize this process.**
        
    *   The **loop at line 6** defines the logic for updating the registers. Since each iteration depends on the previous one, this process **cannot be parallelized** either.
        
*   Hash\_update function
    
    *   Once all the values of the registers have been calculated and assigned to the constants **H\[i\]**, we concatenate them in the **output signal sha256\_digest**.
        

Finite State Machine SHA 256
----------------------------

*   ![FSM_SHA256.png](attachments/3168993281/3199467521.png?width=503)
    
    *   In the **Idle** state, the machine is **waiting** to receive a message.
        
    *   In the **Padding** state, the message is stored in a buffer and padded with a **1 bit followed by zeros**. Additionally, the original **length of the message is added at the end of the buffer as a 64-bit word**.
        
    *   In the **Expand** state, the buffer (after going through the Padding process) is **divided into 512-bit blocks**. Then, **each block is subdivided into 16 words of 32 bits**, which are used to calculate **the remaining 48 words** through an expansion process. As a result, **each block must contain a total of 64 words of 32 bits**.
        
    *   In the **Process** state, the hash calculation is performed. First, the registers are initialized, assigning them the values of the constants **H\[i\]**. Then, these values are updated 64 times throughout the process.
        
        Once the update is complete, the values obtained from the registers are added to the constants **H\[i\]**. If there is more than one block, the process is repeated for the next one, applying the same procedure.
        
    *   In the **Hash\_update** state, all the values obtained are **concatenated into a 256-bit array**, which represents the **final hash** of the received message.
        

Series block diagram
--------------------

*   ![Series block diagram.png](attachments/3168993281/3271196673.png?width=500)
    
    **Serial block diagram** of the **Sha 256** process. We see the inputs, **Message\_in and Message\_len**, and the output, **SHA256\_digest**. The entire process shown is for only one message received.
    

Data-Flow Diagram (DFM) SHA256
------------------------------

*   ![Flow diagram SHA256.png](attachments/3168993281/3202088970.png?width=350)
    

Scheduling Diagrams
-------------------

*   SHA256
    
    *   ![Scheduling SHA256.png](attachments/3168993281/3266641933.png?width=500)
        
    *   We can observe that it is possible to **receive a new message** while the hash of a previous message is still being calculated. This is because, once the **Expand function** releases the **buffer** where the received message was stored, this buffer can be reused to process another message simultaneously.
        
*   Padding
    
    *   ![Scheduling Padding.png](attachments/3168993281/3238789129.png?width=500)
        
    *   In the figure we can notice that the **Padding process** only occurs when the **message is received**. This state cannot be parallelized because we need the **buffer** where the message is received to be **unoccupied** and this happens at the end of the **Expand function**. This is the reason why there is that blank space between each padding.
        
*   Expand
    
    *   ![Scheduling Expand.png](attachments/3168993281/3238658060.png?width=500)
        
    *   The figure shows the **separation of the buffer**, which contains the message with the padding applied, into **512-bit blocks**. Subsequently, for each block, the **additional 32-bit words** necessary for the expansion of the message must be **calculated**. This process is **highly parallelizable**, since the **words generated** within a block do **not depend on other blocks**, which allows taking advantage of a **pipeline structure**.
        
    
    *   ![Scheduling Expand Cycle For.png](attachments/3168993281/3258646543.png?width=500)
    *   The **for** loop is responsible for calculating the **32-bit words for a block**. Each iteration of the cycle represents one column in the message expansion. Since this **for** is inside an **always\_ff block**, all additions are performed within the same clock cycle. However, it is not possible to calculate a word ahead of time, since each value depends on the calculation of the previous word.
        
    *   El ciclo **for** se encarga del cálculo de las palabras de **32 bits** para **un bloque**. Cada iteración del ciclo representa una columna en la expansión del mensaje. Dado que este **for** se encuentra dentro de un bloque **always\_ff**, todas las **sumas** se realizan dentro del **mismo ciclo de reloj**. Sin embargo, no es posible calcular una palabra antes de tiempo, ya que cada valor depende del cálculo de la palabra anterior.
        
    *   ![Scheduling Expand words w.png](attachments/3168993281/3265789970.png?width=500)
        
    *   En el caso de **calcular dos bloques en paralelo** mediante una estructura de **pipeline**, el scheduling del proceso permite **reutilizar los mismos recursos** para las operaciones de **Suma1** y **Suma2**. Mientras se calculan estos valores para un bloque, los **mismos recursos pueden emplearse simultáneamente** para obtener las **palabras correspondientes al siguiente bloque**. De esta manera, se **optimiza** el uso del hardware, asegurando un flujo continuo en la generación de **wj\[i\]** sin interrupciones.
        
*   Process
    
    *   ![Scheduling Process.png](attachments/3168993281/3239378955.png?width=500)
        
    *   En la figura se observa que el estado **process** solo puede **aplicarse por bloques**, ya que depende de los valores de las constantes **H\[i\]**, las cuales se **actualizan** después de procesar **cada bloque**. Debido a esta **dependencia secuencial**, **no** es posible **paralelizar ni implementar** una estructura de **pipeline** en este estado.
        
*   Update\_Hash
    
    *   El diagrama de scheduling de este estado muestra un **único proceso**, que consiste en **almacenar** los valores de **H\[i\]** en una **señal de salida** llamada **sha256\_digest**. Estos **valores** corresponden a los **resultados obtenidos** después de la ejecución del **estado process**.
        

Procesos paralelizables
-----------------------

Cuando se aplica la función SHA-256 a un mensaje cuyo tamaño es mayor a **447 bits**, su longitud se ajusta a un **múltiplo de 512 bits** tras el proceso de **padding**. En el estado **Expand**, el mensaje se divide en bloques de **512 bits**, y a partir de este punto, cada bloque sigue una serie de pasos hasta llegar al estado **Update\_hash**, donde se genera el **hash final**.

Al analizar los diagramas de **Scheduling**, se observa que varios procesos pueden **paralelizarse** para optimizar el uso de los recursos de la tarjeta. Un primer nivel de paralelismo se encuentra en la recepción de datos: es posible recibir un **nuevo mensaje mientras se procesa otro**. Sin embargo, este proceso no es completamente simultáneo, ya que el primer mensaje debe alcanzar el estado **Process** antes de liberar el **buffer** de entrada para el siguiente mensaje.

Otro aspecto paralelizable es el **cálculo de las palabras en el estado Expand**. Dado que las palabras de un bloque **no dependen de otros bloques**, es posible implementar una **paralelización tipo pipeline** para acelerar esta etapa.

Por otro lado, el estado **Process** **no puede** paralelizarse, ya que los valores de hash utilizados para inicializar los registros dependen de los cálculos realizados en los **bloques anteriores**. Esto impone una dependencia secuencial en la actualización del hash final.

Testbench
---------

*   Una de las formas para poner a prueba el código es que vamos a usar lo que se conoce como **“testvector”** son mensajes conocidos y de los cuales se conoce el hash correspondiente al mensaje.
    
    *   Un testvector de **24 bits** de longitud es “`abc`” cuyo output en hexadecimal es:
        
        *   `ba7816bf 8f01cfea 414140de 5dae2223 b00361a3 96177a9c b410ff61 f20015ad`
            
    *   Un testvector de **448 bits** de longitud es “`abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq`“ cuyo output en hexadecimal es:
        
        *   `248d6a61 d20638b8 e5c02693 0c3e6039 a33ce459 64ff2167 f6ecedd4 19db06c1`
            
*   Otra forma de probar el diseño es creando un código en python que calcule el hash a un mensaje cualquiera con sha256 e ir comprobando el paso a paso de cada parte o estado de nuestra máquina.
    

P256
====

AES
===
